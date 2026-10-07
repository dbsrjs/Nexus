import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, SpaceMember } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ChannelsService } from '../channels/channels.service';
import { MAX_THREAD_TURNS } from './prompts/follow-up';
import { RUN_VIEW_SELECT, toRunView } from './run-view';
import { AiThreadsQueryDto } from './dto/threads-query.dto';
import { listContextOf, previewOf, rootQuestionOf, threadContextOf } from './ai-history';
import type { StoredAskInput } from './ai.service';

/** 사슬 하나의 끝과 뿌리→끝 경로. */
interface TipRow {
  rootId: string;
  tipId: string;
  path: string[];
  at: Date;
}

/**
 * AI 기록(19) — 지난 문답 사슬의 목록과 다시 열기. **읽기만 한다** — 적재 · 워커와
 * 의존을 나누려고 `AiService` 와 떼었다.
 *
 * 스키마를 바꾸지 않고 `parent_run_id` 를 재귀 CTE 로 따라 내려간다(설계 D3). 사슬은
 * 엄밀히는 나무다 — 실패한 질문을 다시 보내면 같은 부모에 형제가 생긴다. 보이는 사슬은
 * 뿌리에서 **가장 늦게 끝난 `done` 문답(끝)** 까지의 경로다(D4).
 */
@Injectable()
export class AiHistoryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly channels: ChannelsService,
  ) {}

  /** `GET .../ai/threads` — 끝 시각 내림차순 커서 페이지(D5 · D13). */
  async list(member: SpaceMember, query: AiThreadsQueryDto) {
    const limit = query.limit;
    const tips = await this.tips(member, {
      cursor: query.cursor ?? null,
      limit: limit + 1,
    });
    const page = tips.slice(0, limit);
    const nextCursor = tips.length > limit ? page[page.length - 1].rootId : null;

    // 뿌리(질문 · 근거)와 끝(미리보기)을 한 번에 읽는다 — 사슬마다 묻지 않는다.
    const ids = [...new Set(page.flatMap((t) => [t.rootId, t.tipId]))];
    const rows = await this.prisma.aiRun.findMany({
      where: { id: { in: ids }, spaceId: member.spaceId, userId: member.userId },
      select: { id: true, kind: true, input: true, result: true },
    });
    const byId = new Map(rows.map((r) => [r.id, r]));

    const items = page.flatMap((t) => {
      const root = byId.get(t.rootId);
      const tip = byId.get(t.tipId);
      if (!root || !tip) return [];
      const input = root.input as StoredAskInput;
      return [
        {
          rootRunId: root.id,
          kind: root.kind,
          ...rootQuestionOf(input),
          turnCount: t.path.length,
          lastAt: t.at,
          preview: previewOf(tip.kind, tip.result),
          context: listContextOf(input),
        },
      ];
    });
    return { items, nextCursor };
  }

  /**
   * `GET .../ai/threads/:rootRunId` — 뿌리부터 끝까지. 뿌리가 아닌 id · 끝나지 않은 뿌리 ·
   * 남의 것 · 지금 볼 수 없는 채널의 것은 전부 404 다(목록에 없는 것은 열리지 않는다).
   */
  async thread(member: SpaceMember, rootRunId: string) {
    const [tip] = await this.tips(member, { rootId: rootRunId, cursor: null, limit: 1 });
    if (!tip) throw new NotFoundException('대화를 찾을 수 없습니다');

    const rows = await this.prisma.aiRun.findMany({
      where: { id: { in: tip.path }, spaceId: member.spaceId, userId: member.userId },
      select: { ...RUN_VIEW_SELECT, input: true },
    });
    const byId = new Map(rows.map((r) => [r.id, r]));
    const chain = tip.path.flatMap((id) => {
      const row = byId.get(id);
      return row ? [row] : [];
    });
    // 경로 위 행이 그사이 지워졌으면(부모 cascade) 사슬을 다시 만들 수 없다.
    if (chain.length !== tip.path.length) {
      throw new NotFoundException('대화를 찾을 수 없습니다');
    }

    return {
      rootRunId,
      context: threadContextOf(chain[0].input as StoredAskInput),
      turns: chain.map(({ input, ...view }, i) => {
        const stored = input as StoredAskInput;
        // 뿌리는 지시문 또는 프리셋, 뒤 문답은 지시문뿐이다(13-3 D2).
        const asked =
          i === 0
            ? rootQuestionOf(stored)
            : { question: stored.instruction ?? null, preset: null };
        return { ...toRunView(view), instruction: asked.question, preset: asked.preset };
      }),
    };
  }

  /**
   * 사슬마다 끝과 경로. **본인 것 · 이 스페이스 · 지금 볼 수 있는 채널의 것만**(D6 · D7) —
   * 가시성은 `ChannelsService` 의 판정을 받아 쓴다(여기서 다시 규칙을 쓰지 않는다).
   *
   * `now()` 를 쓰지 않는다(시각 비교가 없다). id 를 `::uuid` 로 캐스팅하지 않는다 —
   * Prisma 의 `String @id` 는 `text` 컬럼이다. `cardinality(path) < 상한` 은 상한을 넘은
   * 행이 있어도 끝없이 돌지 않게 하는 울타리다.
   */
  private async tips(
    member: SpaceMember,
    opts: { rootId?: string; cursor: string | null; limit: number },
  ): Promise<TipRow[]> {
    const viewable = await this.channels.viewableChannelIds(member);
    const onlyRoot = opts.rootId ? Prisma.sql`AND id = ${opts.rootId}` : Prisma.empty;
    const afterCursor =
      opts.cursor !== null
        ? Prisma.sql`WHERE (at, root_id) < (SELECT at, root_id FROM tips WHERE root_id = ${opts.cursor})`
        : Prisma.empty;

    return this.prisma.$queryRaw<TipRow[]>`
      WITH RECURSIVE roots AS (
        SELECT id FROM ai_runs
        WHERE space_id = ${member.spaceId} AND user_id = ${member.userId}
          AND parent_run_id IS NULL AND state = 'done'
          AND (input->>'channelId' IS NULL OR input->>'channelId' = ANY(${viewable}::text[]))
          ${onlyRoot}
      ), t AS (
        SELECT r.id, r.id AS root_id, ARRAY[r.id] AS path,
               coalesce(r.finished_at, r.created_at) AS at
        FROM ai_runs r JOIN roots USING (id)
        UNION ALL
        SELECT c.id, t.root_id, t.path || c.id, coalesce(c.finished_at, c.created_at)
        FROM ai_runs c JOIN t ON c.parent_run_id = t.id
        WHERE c.state = 'done' AND c.space_id = ${member.spaceId}
          AND c.user_id = ${member.userId}
          AND cardinality(t.path) < ${MAX_THREAD_TURNS}
      ), tips AS (
        SELECT DISTINCT ON (root_id) root_id, id AS tip_id, path, at
        FROM t ORDER BY root_id, at DESC, id DESC
      )
      SELECT root_id AS "rootId", tip_id AS "tipId", path, at FROM tips
      ${afterCursor}
      ORDER BY at DESC, root_id DESC
      LIMIT ${opts.limit}
    `;
  }
}
