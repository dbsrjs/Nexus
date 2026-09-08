import { IsInt, IsString, Length, Max, Min, IsOptional } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * 전역 파이프가 `whitelist: true, forbidNonWhitelisted: true` 라 여기 없는
 * 필드는 조용히 지워지지 않고 400 이 된다.
 */
export class SearchIndexDto {
  @IsString()
  @Length(1, 2000)
  query!: string;

  /**
   * 상위 몇 개. 기본 8 · 최대 20.
   *
   * 상한을 두는 이유는 13단계가 이 결과를 프롬프트에 넣기 때문이다 — 20개를
   * 넘으면 컨텍스트가 근거로 가득 차 질문이 묻힌다.
   */
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(20)
  topK?: number;
}
