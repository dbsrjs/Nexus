import { IsIn, IsOptional } from 'class-validator';

export class DownloadAttachmentDto {
  /**
   * `thumb` 면 미리보기용 축소본. **없으면 원본으로 떨어진다** — 파생본이
   * 사라져도 화면이 깨지지 않아야 한다.
   */
  @IsOptional()
  @IsIn(['thumb'])
  variant?: 'thumb';
}
