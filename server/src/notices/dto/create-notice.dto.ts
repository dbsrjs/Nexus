import {
  IsBoolean,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

/** Body for POST /api/notices (lead/admin only). */
export class CreateNoticeDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(300)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  team?: string;

  @IsOptional()
  @IsBoolean()
  pinned?: boolean;

  @IsString()
  @IsNotEmpty()
  body!: string;
}
