import {
  IsBoolean,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
  MinLength,
} from 'class-validator';

export class UpdateSpaceDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(60)
  name?: string;

  @IsOptional()
  @IsUrl()
  iconUrl?: string;

  /** 스프린트 · 번다운을 화면에 보일지(16단계 설계 D31). 화면 노출만 바뀐다. */
  @IsOptional()
  @IsBoolean()
  sprintsEnabled?: boolean;
}
