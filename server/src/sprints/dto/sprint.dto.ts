import { SprintState } from '@prisma/client';
import {
  IsDateString,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateSprintDto {
  @IsString()
  @MinLength(1)
  @MaxLength(60)
  name!: string;

  /** 이 스프린트에서 이루려는 것. 한 줄이면 충분하다. */
  @IsOptional()
  @IsString()
  @MaxLength(200)
  goal?: string;

  /** 비워 두고 만들 수 있다 — 계획 단계에서는 날짜가 아직 없다. */
  @IsOptional()
  @IsDateString()
  startsAt?: string;

  @IsOptional()
  @IsDateString()
  endsAt?: string;
}

/**
 * `state` 를 `active` 로 바꾸면 서비스가 **스페이스당 하나**를 강제한다.
 * 이미 도는 것이 있으면 409 다 — 지금 하는 일이 둘이면 스프린트의 뜻이 없다.
 */
export class UpdateSprintDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(60)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  goal?: string | null;

  @IsOptional()
  @IsDateString()
  startsAt?: string | null;

  @IsOptional()
  @IsDateString()
  endsAt?: string | null;

  @IsOptional()
  @IsEnum(SprintState)
  state?: SprintState;
}

export class ListSprintsDto {
  @IsOptional()
  @IsEnum(SprintState)
  state?: SprintState;
}
