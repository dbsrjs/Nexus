import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { Chunk } from './chunker';
import { fuseRankings, tsQueryOf } from './lexical';

/**
 * `number[]` → pgvector 리터럴.
 *
 * **`embedding` 은 Prisma 클라이언트로 읽고 쓸 수 없다** — 스키마가
 * `Unsupported("vector(768)")` 이라 클라이언트가 필드를 아예 만들지 않는다.
 * 삽입도 조회도 raw SQL 이고, 값은 이 문자열로 넘겨 `::vector` 로 캐스팅한다.
 */
export function toVectorLiteral(v: number[]): string {
  const parts = v.map((x) => {
    if (!Number.isFinite(x)) {
      throw new Error('임베딩에 유한하지 않은 값이 있습니다 (NaN · Infinity).');
    }
    // toFixed 로 지수 표기를 피한다. 6자리면 코사인 거리에 영향이 없다.
    return String(Number(x.toFixed(6)));
  });
  return `[${parts.join(',')}]`;
}

/**
 * 하이브리드 검색에서 각 갈래가 가져오는 후보 수. 합친 뒤 `topK`(최대 20)만
 * 남긴다. **후보가 topK 와 같으면 합치는 의미가 줄어든다** — 한쪽에서 9위였던
 * 것이 다른 쪽 2위와 만나 올라오는 것이 RRF 의 이득이라, 넉넉히 가져온다.
 * HNSW 의 기본 `ef_search`(40) 안이라 벡터 쪽 후보를 다 채운다.
 */
export const HYBRID_CANDIDATES = 30;

type ChunkRow = {
  id: string;
  path: string;
  lang: string | null;
  start_line: number;
  end_line: number;
  content: string;
  commit_sha: string;
  score: number;
};

function toHit(r: ChunkRow): ChunkHit {
  return {
    id: r.id,
    path: r.path,
    lang: r.lang,
    startLine: r.start_line,
    endLine: r.end_line,
    content: r.content,
    commitSha: r.commit_sha,
    score: Number(r.score),
  };
}

export interface ChunkHit {
  id: string;
  path: string;
  lang: string | null;
  startLine: number;
  endLine: number;
  content: string;
  commitSha: string;
  /**
   * 정렬 기준값. **갈래마다 단위가 다르다** — 벡터는 코사인 유사도(0~1),
   * 낱말은 IDF 합, 하이브리드(운영 경로)는 RRF 점수다. 순서만 뜻이 있고
   * 갈래끼리 비교하지 않는다.
   */
  score: number;
}

@Injectable()
export class IndexChunksRepository {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * 파일 하나의 청크를 통째로 갈아 끼운다.
   *
   * **저장소 전체를 한 트랜잭션으로 묶지 않는다** — 2,300개 행을 한 번에 쓰는
   * 트랜잭션은 몇 분을 잡고 있고, 중간에 끊기면 처음부터다. 파일 단위면
   * 멱등이라 다시 돌면 같은 결과로 덮인다 (설계 §4).
   */
  async replaceFile(input: {
    spaceId: string;
    repoId: string;
    path: string;
    lang: string | null;
    commitSha: string;
    chunks: Chunk[];
    embeddings: number[][];
  }): Promise<void> {
    const { spaceId, repoId, path, lang, commitSha, chunks, embeddings } = input;
    if (chunks.length !== embeddings.length) {
      throw new Error('청크 수와 임베딩 수가 다릅니다.');
    }

    await this.prisma.$transaction(async (tx) => {
      // id 컬럼은 uuid 가 아니라 **text** 다. ::uuid 로 캐스팅하면
      // `operator does not exist: text = uuid` 로 실패한다.
      await tx.$executeRaw`
        DELETE FROM repo_index_chunks
         WHERE space_id = ${spaceId} AND repo_id = ${repoId} AND path = ${path}
      `;

      for (let i = 0; i < chunks.length; i++) {
        const c = chunks[i];
        // id 를 Node 에서 만든다. 이 컬럼에는 DB 기본값이 없다 —
        // Prisma 가 `@default(uuid())` 를 클라이언트 쪽에서 채우기 때문이다.
        await tx.$executeRaw`
          INSERT INTO repo_index_chunks
            (id, space_id, repo_id, path, lang, start_line, end_line, content, embedding, commit_sha)
          VALUES
            (${randomUUID()}, ${spaceId}, ${repoId}, ${path}, ${lang},
             ${c.startLine}, ${c.endLine}, ${c.content},
             ${toVectorLiteral(embeddings[i])}::vector, ${commitSha})
        `;
      }
    });
  }

  async deleteFile(spaceId: string, repoId: string, path: string): Promise<void> {
    await this.prisma.$executeRaw`
      DELETE FROM repo_index_chunks
       WHERE space_id = ${spaceId} AND repo_id = ${repoId} AND path = ${path}
    `;
  }

  /** 전체 재인덱싱 전에 비운다. 지운 뒤 새로 쌓지 못하면 빈 채로 남지만, 그것은 상태가 말한다. */
  async deleteRepo(spaceId: string, repoId: string): Promise<void> {
    await this.prisma.$executeRaw`
      DELETE FROM repo_index_chunks WHERE space_id = ${spaceId} AND repo_id = ${repoId}
    `;
  }

  /**
   * id 로 청크를 읽는다. `ids` 순서를 지킨다 — 인용 번호([1] [2]…)가 이
   * 순서에 묶여 있다. 다른 스페이스 · 저장소의 id 는 `WHERE` 가 걸러낸다.
   * `score` 는 검색이 아니라서 0 이다.
   */
  async findByIds(spaceId: string, repoId: string, ids: string[]): Promise<ChunkHit[]> {
    if (ids.length === 0) return [];
    const rows = await this.prisma.repoIndexChunk.findMany({
      where: { id: { in: ids }, spaceId, repoId },
      select: {
        id: true,
        path: true,
        lang: true,
        startLine: true,
        endLine: true,
        content: true,
        commitSha: true,
      },
    });
    const byId = new Map(rows.map((r) => [r.id, r]));
    return ids.flatMap((id) => {
      const r = byId.get(id);
      return r ? [{ ...r, score: 0 }] : [];
    });
  }

  async countFor(spaceId: string, repoId: string): Promise<number> {
    const rows = await this.prisma.$queryRaw<{ count: bigint }[]>`
      SELECT COUNT(*) AS count FROM repo_index_chunks
       WHERE space_id = ${spaceId} AND repo_id = ${repoId}
    `;
    // COUNT 는 bigint 로 온다. JSON.stringify 가 던지므로 여기서 접는다.
    return Number(rows[0]?.count ?? 0);
  }

  /**
   * 벡터 검색.
   *
   * **`space_id` 가 `WHERE` 에 있다.** `repo_id` 만으로 좁혀지지만 격리 규칙 1 은
   * "부모를 타고 유추할 수 있어도" 넣으라고 되어 있다 — 벡터 검색도 예외가 아니다.
   *
   * **HNSW 는 필터를 나중에 적용한다.** 선택도가 높은 `WHERE` 를 걸면 상위 K 를
   * 못 채울 수 있는데, 수천 행 규모에서는 문제가 되지 않는다. 실제로 덜 나오는
   * 것을 보면 `hnsw.ef_search` 를 올리는 것이 손잡이다 — 지금 손대지 않는다.
   */
  async search(
    spaceId: string,
    repoId: string,
    embedding: number[],
    topK: number,
  ): Promise<ChunkHit[]> {
    const literal = toVectorLiteral(embedding);

    const rows = await this.prisma.$queryRaw<ChunkRow[]>`
      SELECT id, path, lang, start_line, end_line, content, commit_sha,
             1 - (embedding <=> ${literal}::vector) AS score
        FROM repo_index_chunks
       WHERE space_id = ${spaceId} AND repo_id = ${repoId} AND embedding IS NOT NULL
       ORDER BY embedding <=> ${literal}::vector
       LIMIT ${Prisma.raw(String(Math.trunc(topK)))}
    `;
    return rows.map(toHit);
  }

  /**
   * 낱말 검색. `terms` 는 `queryTermsOf()` 가 만든 것이다(`[\p{L}\p{N}]` 만).
   * `score` 는 맞은 낱말들의 **IDF 합**이 주이고, 낱말마다 `ts_rank`(빈도 ·
   * 길이 보정 — 정규화 1)를 얹는다. BM25 를 흉내 낸 모양이다. IDF 만 쓰면
   * 같은 낱말 집합에 맞은 청크끼리 동점이 많아 경로 이름순으로 갈렸다
   * (`.claude/` 가 늘 위) — 빈도를 얹자 평가 MRR 이 0.288 → 0.390(진행 기록
   * «RAG 강화»). `* 10` 은 IDF 가 앞서게 둔 크기다(`ts_rank` 가 0.01~0.03 대라
   * 보정이 10~30% 안에 머문다). 10 · 30 · 100 이 거의 같아 작은 쪽을 골랐다.
   *
   * IDF 는 **이 저장소 안에서** 센다(`space_id` · `repo_id` 로 좁힌 COUNT).
   * 저장소마다 흔한 낱말이 다르다 — Dart 저장소의 `final` 은 흔하지만
   * TypeScript 저장소에서는 드물다.
   */
  async searchLexical(
    spaceId: string,
    repoId: string,
    terms: string[],
    topK: number,
  ): Promise<ChunkHit[]> {
    if (terms.length === 0) return [];
    const queries = terms.map(tsQueryOf);

    const rows = await this.prisma.$queryRaw<ChunkRow[]>`
      WITH t AS (
        SELECT to_tsquery('simple', q) AS q
          FROM unnest(${queries}::text[]) AS u(q)
      ),
      n AS (
        SELECT COUNT(*)::float8 AS total FROM repo_index_chunks
         WHERE space_id = ${spaceId} AND repo_id = ${repoId}
      ),
      w AS (
        SELECT t.q, ln(1 + (n.total - d.df + 0.5) / (d.df + 0.5)) AS idf
          FROM t CROSS JOIN n
         CROSS JOIN LATERAL (
           SELECT COUNT(*)::float8 AS df FROM repo_index_chunks c
            WHERE c.space_id = ${spaceId} AND c.repo_id = ${repoId} AND c.search_tsv @@ t.q
         ) d
         WHERE d.df > 0
      )
      SELECT c.id, c.path, c.lang, c.start_line, c.end_line, c.content, c.commit_sha,
             SUM(w.idf * (1 + ts_rank(c.search_tsv, w.q, 1) * 10)) AS score
        FROM repo_index_chunks c
        JOIN w ON c.search_tsv @@ w.q
       WHERE c.space_id = ${spaceId} AND c.repo_id = ${repoId}
       GROUP BY c.id
       ORDER BY score DESC, c.path, c.start_line
       LIMIT ${Prisma.raw(String(Math.trunc(topK)))}
    `;
    return rows.map(toHit);
  }

  /**
   * 벡터 + 낱말을 순위로 합친다(`fuseRankings`). 두 갈래를 함께 돌린다 —
   * 서로 기다릴 이유가 없다. `score` 는 RRF 점수다(코사인 유사도가 아니다).
   *
   * 벡터를 앞 목록으로 넘긴다 — 동점이면 뜻으로 찾은 쪽이 앞선다.
   */
  async searchHybrid(
    spaceId: string,
    repoId: string,
    embedding: number[],
    terms: string[],
    topK: number,
  ): Promise<ChunkHit[]> {
    const [byVector, byWords] = await Promise.all([
      this.search(spaceId, repoId, embedding, HYBRID_CANDIDATES),
      this.searchLexical(spaceId, repoId, terms, HYBRID_CANDIDATES),
    ]);
    return fuseRankings([byVector, byWords], topK).map(({ fused, ...hit }) => ({
      ...hit,
      score: fused,
    }));
  }
}
