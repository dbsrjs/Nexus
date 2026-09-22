import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { AiRunKind, AiRunState, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { LLM_PROVIDER, LlmMessage, LlmProvider } from '../llm/llm.provider';
import { IndexingService } from '../repos/indexing/indexing.service';
import { ChunkHit } from '../repos/indexing/index-chunks.repository';
import { AiQueueService } from './ai-queue.service';
import { TranscriptMessage, buildTranscript } from './transcript';
import { promptHash } from './prompt-hash';
import { AskInputShape, AskPreset, validateAskRequest } from './ask-request';
import { Citation, citationsOf } from './code-context';
import { buildAskPrompt } from './prompts/build';

/** 채널만 줬을 때 읽는 최근 최상위 메시지 수 (13-2 설계 §2). */
export const RECENT_MESSAGES = 50;

/** 저장소에서 몇 청크를 가져오나. 원래 설계 §7.3 의 topK=8. */
export const CODE_TOP_K = 8;

/** 프리셋 + 저장소일 때 대화 끝에서 검색어로 쓰는 길이. 지시문 상한과 같다. */
export const SEARCH_QUERY_MAX = 2000;

/**
 * `ai_runs.input` 에 저장하는 모양. **적재 시점에 확정된 것만 담는다** —
 * 워커가 이것만으로 같은 프롬프트를 다시 만든다 (13-2 설계 §2).
 */
export interface StoredAskInput {
  instruction?: string;
  preset?: AskPreset;
  channelId?: string;
  messageIds?: string[];
  repoId?: string;
  chunkIds?: string[];
}

/** 워커가 받는 것. 프롬프트와 함께, 결과에 실을 인용까지. */
export interface PreparedPrompt {
  kind: AiRunKind;
  messages: LlmMessage[];
  json: boolean;
  citations: Citation[];
}

export interface StartResult {
  runId: string;
  state: 'queued' | 'done';
}

/** `<@uuid>` 를 본문에서 찾는다. 이름 조회를 한 번에 하기 위함이다. */
const MENTION = /<@([^>]+)>/g;

@Injectable()
export class AiService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(LLM_PROVIDER) private readonly llm: LlmProvider | null,
    private readonly queue: AiQueueService,
    private readonly indexing: IndexingService,
  ) {}

  /**
   * AI 에 묻는다 (13-2). 검증 → 대화 · 코드 조립 → 프롬프트 → 캐시 또는 적재.
   *
   * **LLM 미설정 503 이 다른 어떤 검증보다 먼저다** — 13-1 과 같다.
   */
  async ask(spaceId: string, userId: string, dto: AskInputShape): Promise<StartResult> {
    const llm = this.requireLlm();
    const req = validateAskRequest(dto);

    let transcript: string | null = null;
    let messageIds: string[] | undefined;
    if (req.channelId !== null) {
      await this.requireChannel(spaceId, userId, req.channelId);
      const messages =
        req.messageIds !== null
          ? await this.loadPicked(spaceId, req.channelId, req.messageIds)
          : await this.loadRecent(spaceId, req.channelId);
      // 빈 대화를 요약하게 하지 않는다.
      if (messages.length === 0) {
        throw new BadRequestException('대화에 메시지가 없습니다');
      }
      messageIds = messages.map((m) => m.id);
      transcript = await this.transcriptOf(spaceId, messages);
    }

    let chunks: ChunkHit[] = [];
    if (req.repoId !== null) {
      // 검색어는 지시문이다. 프리셋이면 대화가 무엇을 말하는지로 찾는다 —
      // 프리셋은 대화를 요구하므로(validateAskRequest) transcript 가 있다.
      const query = req.instruction ?? (transcript ?? '').slice(-SEARCH_QUERY_MAX);
      // 저장소 소속(404) · 임베딩 미설정 · 모델 불일치(503)는 search() 가 본다.
      ({ chunks } = await this.indexing.search(spaceId, req.repoId, query, CODE_TOP_K));
    }

    const built = buildAskPrompt(req, { transcript, chunks });
    const input: StoredAskInput = {
      ...(req.instruction !== null ? { instruction: req.instruction } : {}),
      ...(req.preset !== null ? { preset: req.preset } : {}),
      ...(req.channelId !== null ? { channelId: req.channelId, messageIds } : {}),
      ...(req.repoId !== null
        ? { repoId: req.repoId, chunkIds: chunks.map((c) => c.id) }
        : {}),
    };
    return this.start(spaceId, userId, built.kind, input, built.messages, llm);
  }

  /**
   * 워커가 부른다. **적재 때와 같은 프롬프트를 다시 만든다** — 프롬프트를
   * 행에 저장하면 같은 것이 두 곳에 있게 되고, 프롬프트를 고칠 때 큐에 남은
   * 것만 옛 문구로 돈다. 조립은 적재와 같은 `buildAskPrompt()` 다.
   *
   * 워커는 이미 권한을 통과한 요청을 다시 도는 것이라 가시성은 다시 보지
   * 않는다 — 대신 스페이스는 맞춘다.
   */
  async loadPrompt(spaceId: string, raw: Prisma.JsonValue): Promise<PreparedPrompt> {
    const input = raw as StoredAskInput;

    let transcript: string | null = null;
    if (input.messageIds) {
      const messages = await this.prisma.message.findMany({
        where: { id: { in: input.messageIds }, spaceId },
        orderBy: { createdAt: 'asc' },
        select: MESSAGE_SELECT,
      });
      transcript = await this.transcriptOf(spaceId, messages);
    }

    let chunks: ChunkHit[] = [];
    if (input.repoId && input.chunkIds) {
      chunks = await this.indexing.chunksByIds(spaceId, input.repoId, input.chunkIds);
      // 그사이 재인덱싱이 청크를 갈아 끼웠다. 빼고 답하면 인용이 빈다 —
      // 던져서 fatal 로 끝낸다. 다시 물으면 새 검색으로 풀린다 (설계 §2).
      if (chunks.length !== input.chunkIds.length) {
        throw new Error('참고한 코드가 다시 인덱싱되어 사라졌습니다.');
      }
    }

    // 13-1 에서 적재된 행은 `{channelId, messageIds}` 뿐이다 — 요약으로 읽는다.
    const preset = input.preset ?? (input.instruction === undefined ? 'summary' : null);
    const built = buildAskPrompt(
      { instruction: input.instruction ?? null, preset },
      { transcript, chunks },
    );
    return { ...built, citations: citationsOf(chunks) };
  }

  /** 러너가 「포기했는가」를 판정하는 데만 쓴다. */
  async getRunState(runId: string): Promise<AiRunState | null> {
    const run = await this.prisma.aiRun.findUnique({
      where: { id: runId },
      select: { state: true },
    });
    return run?.state ?? null;
  }

  async getRun(spaceId: string, userId: string, runId: string) {
    // **본인 것만.** 같은 스페이스라도 남의 질문과 답을 읽을 이유가 없다.
    const run = await this.prisma.aiRun.findFirst({
      where: { id: runId, spaceId, userId },
      select: {
        id: true,
        kind: true,
        state: true,
        result: true,
        error: true,
        model: true,
        promptTokens: true,
        completionTokens: true,
        createdAt: true,
        finishedAt: true,
      },
    });
    if (!run) throw new NotFoundException('실행을 찾을 수 없습니다');
    return { runId: run.id, ...run, id: undefined };
  }

  /** 캐시를 보고, 없으면 적재한다. */
  private async start(
    spaceId: string,
    userId: string,
    kind: AiRunKind,
    input: object,
    prompt: LlmMessage[],
    llm: LlmProvider,
  ): Promise<StartResult> {
    const hash = promptHash(kind, llm.modelId, prompt);

    // **`spaceId` 뿐 아니라 `userId` 도 WHERE 에 넣는다.** 스펙 §4(캐시
    // 조회는 spaceId 로만)와 §9(getRun() 은 본인 것만)가 서로 모순이었다 —
    // §4 대로면 bob 이 alice 와 같은 구간을 고를 때 프롬프트가 바이트
    // 단위로 같아 같은 promptHash 가 나오고, 캐시가 **alice 의 runId** 를
    // 돌려준다. 그런데 §9 의 getRun() 은 userId 가 다르면 404 이므로 bob 의
    // GET 이 영구히 404 가 된다(다시 눌러도 같은 캐시를 가리킨다). §9 의
    // 근거(「같은 스페이스라도 남의 질문과 답을 읽을 이유가 없다」)가 §4 의
    // 쿼터 절약보다 무겁다고 보고 §9 를 택한다 — 최종 whole-branch 리뷰
    // Important ①.
    const cached = await this.prisma.aiRun.findFirst({
      where: { spaceId, userId, promptHash: hash, state: AiRunState.done },
      orderBy: { createdAt: 'desc' },
      select: { id: true },
    });
    if (cached) return { runId: cached.id, state: 'done' };

    const runId = await this.queue.enqueue({
      spaceId,
      userId,
      kind,
      input,
      promptHash: hash,
    });
    return { runId, state: 'queued' };
  }

  private requireLlm(): LlmProvider {
    if (!this.llm) {
      throw new ServiceUnavailableException('AI 가 설정되지 않았습니다.');
    }
    return this.llm;
  }

  /**
   * 채널 가시성 규칙을 그대로 태운다 — `issues.service.ts` 의
   * `requireVisibleMessage()` 와 같은 형태다. 볼 수 없으면 404(403 은 "그
   * 채널이 존재한다"를 알려 준다).
   */
  private async requireChannel(spaceId: string, userId: string, channelId: string) {
    const channel = await this.prisma.channel.findFirst({
      where: {
        id: channelId,
        spaceId,
        OR: [{ isPrivate: false }, { members: { some: { userId } } }],
      },
      select: { id: true },
    });
    if (!channel) throw new NotFoundException('채널을 찾을 수 없습니다');
  }

  /** 고른 메시지. 중복은 `validateAskRequest` 가 이미 접었다. */
  private async loadPicked(spaceId: string, channelId: string, ids: string[]) {
    const messages = await this.prisma.message.findMany({
      where: { id: { in: ids }, spaceId, channelId },
      orderBy: { createdAt: 'asc' },
      select: MESSAGE_SELECT,
    });

    // **일부만 요약하지 않는다** (판단 #4). 고른 것 중 하나라도 없으면 404 다 —
    // 조용히 빼면 사용자는 전부 요약됐다고 믿는다.
    if (messages.length !== ids.length) {
      throw new NotFoundException('메시지를 찾을 수 없습니다');
    }
    return messages;
  }

  /**
   * 채널의 최근 최상위 메시지. **채널 목록과 같은 기준**(`parentId` 없음)이라
   * 스레드 답글은 빠진다 — 사용자가 채널에서 보는 대화가 곧 요약 대상이다.
   */
  private async loadRecent(spaceId: string, channelId: string) {
    const latest = await this.prisma.message.findMany({
      where: { spaceId, channelId, parentId: null },
      orderBy: { createdAt: 'desc' },
      take: RECENT_MESSAGES,
      select: MESSAGE_SELECT,
    });
    return latest.reverse();
  }

  private async transcriptOf(spaceId: string, messages: LoadedMessage[]): Promise<string> {
    const names = await this.mentionNames(spaceId, messages.map((m) => m.body));
    return buildTranscript(toTranscript(messages), names);
  }

  /**
   * 본문들에서 `<@id>` 를 모아 이름을 조회한다. **스페이스 멤버 중에서만
   * 찾는다** — 본문의 `<@id>` 는 검증되지 않은 사용자 입력이라 다른
   * 스페이스 사람의 id 를 담을 수 있다. 전역 `User` 테이블로 찾으면 그
   * 사람의 실명이 이 스페이스의 요약문에 새어 나간다(테넌트 격리 위반).
   * 스페이스 밖 id 는 이 Map 에 없으므로 `buildTranscript` 의
   * `withNames()` 가 이미 가진 `@(알 수 없음)` 폴백이 그대로 처리한다.
   */
  private async mentionNames(
    spaceId: string,
    bodies: string[],
  ): Promise<Map<string, string>> {
    const ids = new Set<string>();
    for (const body of bodies) {
      for (const m of body.matchAll(MENTION)) ids.add(m[1]);
    }
    if (ids.size === 0) return new Map();

    const members = await this.prisma.spaceMember.findMany({
      where: { spaceId, userId: { in: [...ids] } },
      select: { userId: true, user: { select: { name: true } } },
    });
    return new Map(members.map((m) => [m.userId, m.user.name]));
  }
}

const MESSAGE_SELECT = {
  id: true,
  body: true,
  deletedAt: true,
  createdAt: true,
  author: { select: { name: true } },
  // `Attachment.name` 이다 — `filename` 이 아니다 (schema.prisma:478).
  attachments: { select: { name: true } },
} satisfies Prisma.MessageSelect;

type LoadedMessage = {
  id: string;
  body: string;
  deletedAt: Date | null;
  createdAt: Date;
  author: { name: string };
  attachments: Array<{ name: string }>;
};

function toTranscript(messages: LoadedMessage[]): TranscriptMessage[] {
  return messages.map((m) => ({
    body: m.body,
    deletedAt: m.deletedAt,
    createdAt: m.createdAt,
    authorName: m.author.name,
    attachmentNames: m.attachments.map((a) => a.name),
  }));
}
