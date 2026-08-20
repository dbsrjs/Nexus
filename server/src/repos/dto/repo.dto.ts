import { RepoProvider } from '@prisma/client';
import {
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';

/**
 * 수동 등록. OAuth 없이 붙이는 길이라 사람이 저장소 경로를 직접 적는다.
 */
export class CreateRepoDto {
  @IsEnum(RepoProvider)
  provider!: RepoProvider;

  /** `소유자/이름`. GitHub 의 full_name 과 같은 형식이다. */
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  fullPath!: string;

  /** 비우면 이벤트를 적재만 하고 채널에는 올리지 않는다. */
  @IsOptional()
  @IsUUID()
  linkedChannelId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  defaultBranch?: string;
}
