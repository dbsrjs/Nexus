import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

/** 목록 기본 크기. 패널 안이라 공용 기본(30)보다 작다(19 설계 D13). */
export const THREAD_PAGE = 20;

/**
 * `GET .../ai/threads` 의 커서 페이지. `PaginationDto` 와 같은 규칙에 기본 크기만 다르다 —
 * 그쪽의 기본값이 필드 초기값이라 상속해서는 「안 줌」과 「30 을 줌」을 가를 수 없다.
 * 커서는 다음 페이지의 기준이 되는 사슬(뿌리 `runId`)이다.
 */
export class AiThreadsQueryDto {
  @IsOptional()
  @IsString()
  cursor?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit: number = THREAD_PAGE;
}
