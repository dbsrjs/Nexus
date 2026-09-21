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
import { AiQueueService } from './ai-queue.service';
import {
  MAX_TRANSCRIPT_MESSAGES,
  TranscriptMessage,
  buildTranscript,
} from './transcript';
import { promptHash } from './prompt-hash';
import { summarizePrompt } from './prompts/summarize';

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
  ) {}

  async summarize(
    spaceId: string,
    userId: string,
    dto: { channelId: string; messageIds: string[] },
  ): Promise<StartResult> {
    const llm = this.requireLlm();
    const messages = await this.loadMessages(spaceId, userId, dto);
    const names = await this.mentionNames(spaceId, messages.map((m) => m.body));

    const prompt = summarizePrompt(
      buildTranscript(toTranscript(messages), names),
    );
    return this.start(spaceId, userId, AiRunKind.summarize, dto, prompt, llm);
  }

  /**
   * 워커가 부른다. **적재 때와 같은 프롬프트를 다시 만든다** — 프롬프트를
   * 행에 저장하면 같은 것이 두 곳에 있게 되고, 프롬프트를 고칠 때 큐에 남은
   * 것만 옛 문구로 돈다.
   */
  async loadPrompt(
    spaceId: string,
    kind: AiRunKind,
    input: Prisma.JsonValue,
  ): Promise<LlmMessage[]> {
    const dto = input as { channelId: string; messageIds: string[] };
    if (kind !== AiRunKind.summarize) {
      throw new Error(`아직 지원하지 않는 종류입니다: ${kind}`);
    }
    // 워커는 이미 권한을 통과한 요청을 다시 도는 것이라 가시성은 다시 보지
    // 않는다 — 대신 스페이스는 맞춘다.
    const messages = await this.prisma.message.findMany({
      where: { id: { in: dto.messageIds }, spaceId },
      orderBy: { createdAt: 'asc' },
      select: MESSAGE_SELECT,
    });
    const names = await this.mentionNames(spaceId, messages.map((m) => m.body));
    return summarizePrompt(buildTranscript(toTranscript(messages), names));
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

    // **`spaceId` 를 WHERE 에 넣는다** — 격리는 해시가 아니라 쿼리로 지킨다.
    const cached = await this.prisma.aiRun.findFirst({
      where: { spaceId, promptHash: hash, state: AiRunState.done },
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
   * 고른 메시지를 읽는다. **채널 가시성 규칙을 그대로 태운다** —
   * `issues.service.ts` 의 `requireVisibleMessage()` 와 같은 형태다.
   */
  private async loadMessages(
    spaceId: string,
    userId: string,
    dto: { channelId: string; messageIds: string[] },
  ) {
    if (dto.messageIds.length === 0) {
      throw new BadRequestException('메시지를 한 개 이상 골라야 합니다');
    }
    if (dto.messageIds.length > MAX_TRANSCRIPT_MESSAGES) {
      throw new BadRequestException(
        `한 번에 ${MAX_TRANSCRIPT_MESSAGES}개까지 요약할 수 있습니다`,
      );
    }

    const channel = await this.prisma.channel.findFirst({
      where: {
        id: dto.channelId,
        spaceId,
        OR: [{ isPrivate: false }, { members: { some: { userId } } }],
      },
      select: { id: true },
    });
    // 볼 수 없으면 404. 403 은 "그 채널이 존재한다"를 알려 준다.
    if (!channel) throw new NotFoundException('채널을 찾을 수 없습니다');

    // 중복 id 는 먼저 접는다. SQL `IN` 도 중복을 접으므로 접지 않으면 중복
    // 만으로 개수가 안 맞아 "일부 누락"(판단 #4)으로 오판해 404 가 난다 —
    // 판단 #4 의 취지는 누락 방지이지 중복 거부가 아니다. 상한 검사는 위에서
    // 이미 원본 길이로 했으므로, 여기서 접어도 상한을 우회하는 통로가 되지
    // 않는다.
    const ids = [...new Set(dto.messageIds)];

    const messages = await this.prisma.message.findMany({
      where: { id: { in: ids }, spaceId, channelId: dto.channelId },
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
