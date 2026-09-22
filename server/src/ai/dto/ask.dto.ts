import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsDefined,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { MAX_TRANSCRIPT_MESSAGES } from '../transcript';
import { ASK_PRESETS, AskPreset, MAX_INSTRUCTION } from '../ask-request';

/** 무엇을 근거로 묻나. 조합 규칙(최소 하나 · 조건부)은 `validateAskRequest()` 가 본다. */
export class AskContextDto {
  @IsOptional()
  @IsUUID()
  channelId?: string;

  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(MAX_TRANSCRIPT_MESSAGES)
  @IsUUID('4', { each: true })
  messageIds?: string[];

  @IsOptional()
  @IsUUID()
  repoId?: string;
}

/**
 * `POST /ai/ask` (13-2 설계 §1).
 *
 * **배타 · 조건부 규칙은 데코레이터로 쓰지 않는다** — `validateAskRequest()`
 * 한 곳에서 본다. 여기서는 모양과 상한만 막는다.
 */
export class AskDto {
  @IsOptional()
  @IsString()
  @MaxLength(MAX_INSTRUCTION)
  instruction?: string;

  @IsOptional()
  @IsIn(ASK_PRESETS)
  preset?: AskPreset;

  @IsDefined()
  @ValidateNested()
  @Type(() => AskContextDto)
  context!: AskContextDto;
}
