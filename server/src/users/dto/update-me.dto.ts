import { UserStatus } from '@prisma/client';
import { IsIn, IsOptional, IsString, IsUrl, MaxLength, MinLength } from 'class-validator';

const STATUSES: UserStatus[] = ['online', 'away', 'offline'];

export class UpdateMeDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(50)
  name?: string;

  @IsOptional()
  @IsUrl()
  avatarUrl?: string;

  @IsOptional()
  @IsIn(STATUSES)
  globalStatus?: UserStatus;
}
