import { IsNotEmpty, IsString } from 'class-validator';

/**
 * Body for POST /api/issues/:id/comments.
 */
export class CreateIssueCommentDto {
  @IsString()
  @IsNotEmpty()
  body!: string;
}
