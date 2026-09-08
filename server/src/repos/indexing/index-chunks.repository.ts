import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { Chunk } from './chunker';

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

export interface ChunkHit {
  id: string;
  path: string;
  lang: string | null;
  startLine: number;
  endLine: number;
  content: string;
  commitSha: string;
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

    const rows = await this.prisma.$queryRaw<
      Array<{
        id: string;
        path: string;
        lang: string | null;
        start_line: number;
        end_line: number;
        content: string;
        commit_sha: string;
        score: number;
      }>
    >`
      SELECT id, path, lang, start_line, end_line, content, commit_sha,
             1 - (embedding <=> ${literal}::vector) AS score
        FROM repo_index_chunks
       WHERE space_id = ${spaceId} AND repo_id = ${repoId} AND embedding IS NOT NULL
       ORDER BY embedding <=> ${literal}::vector
       LIMIT ${Prisma.raw(String(Math.trunc(topK)))}
    `;

    return rows.map((r) => ({
      id: r.id,
      path: r.path,
      lang: r.lang,
      startLine: r.start_line,
      endLine: r.end_line,
      content: r.content,
      commitSha: r.commit_sha,
      score: r.score,
    }));
  }
}
