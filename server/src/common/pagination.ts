import { PaginationDto } from './dto/pagination.dto';

/**
 * 커서 페이지(`?cursor=&limit=`)의 공용 조각. 메시지 · 스레드 · 파일 · 알림이 같은 네 줄
 * (`limit + 1` 로 하나 더 읽고 · 커서 다음부터 · 넘쳤는지 보고 · 마지막 id 를 커서로)을
 * 각자 들고 있었다.
 *
 * 정렬(`orderBy`)은 부르는 쪽이 정한다 — 알림은 `[createdAt, id]` 처럼 자리마다 다르다.
 */
export function cursorArgs(query: PaginationDto) {
  const limit = query.limit ?? 30;
  return {
    limit,
    /** Prisma `findMany` 에 그대로 펼친다. 다음 페이지가 있는지 알려고 하나 더 읽는다. */
    args: {
      take: limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
    },
  };
}

/** 하나 더 읽은 결과를 페이지와 다음 커서로 자른다. 끝이면 커서는 `null`. */
export function pageOf<T extends { id: string }>(rows: T[], limit: number) {
  const hasMore = rows.length > limit;
  const page = hasMore ? rows.slice(0, limit) : rows;
  return { page, nextCursor: hasMore ? page[page.length - 1].id : null };
}
