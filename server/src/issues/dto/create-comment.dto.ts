import { IsString, MaxLength, MinLength } from 'class-validator';

/**
 * 이슈 댓글. 수정 · 삭제는 아직 없다 — 메시지가 소프트 삭제인 것과 맞출지
 * 정해야 하는데, 그 판단이 이 조각(9-2a)의 크기를 넘는다.
 */
export class CreateIssueCommentDto {
  @IsString()
  @MinLength(1)
  @MaxLength(10000)
  body!: string;
}
