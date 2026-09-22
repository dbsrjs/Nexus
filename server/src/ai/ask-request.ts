import { BadRequestException } from '@nestjs/common';
import { MAX_TRANSCRIPT_MESSAGES } from './transcript';

/** 서버가 가진 프롬프트 템플릿 이름 (13-2 설계 D2 · D3). */
export const ASK_PRESETS = ['summary', 'issue'] as const;
export type AskPreset = (typeof ASK_PRESETS)[number];

/** 지시문 상한. 넘으면 400 — 조용히 자르지 않는다 (판단 #4). */
export const MAX_INSTRUCTION = 2000;

/** 검증을 통과한 요청. 없는 것은 `undefined` 가 아니라 `null` 이다. */
export interface AskRequest {
  instruction: string | null;
  preset: AskPreset | null;
  channelId: string | null;
  messageIds: string[] | null;
  repoId: string | null;
}

/** DTO 와 같은 모양. 순수 함수로 두려고 DTO 클래스를 import 하지 않는다. */
export interface AskInputShape {
  instruction?: string;
  preset?: AskPreset;
  context: { channelId?: string; messageIds?: string[]; repoId?: string };
}

/**
 * 요청의 조합 규칙을 본다 (13-2 설계 §1). **순수 함수다.**
 *
 * 데코레이터로 쓰기 어려운 배타 · 조건부 규칙이 여기 모인다. 상한은 DTO 도
 * 막지만 여기서 한 번 더 본다 — 서비스를 직접 부르는 경로에는 DTO 그물이
 * 없다(13-1 의 상한과 같은 자리).
 */
export function validateAskRequest(dto: AskInputShape): AskRequest {
  const instruction = dto.instruction?.trim() ?? null;
  const preset = dto.preset ?? null;

  if (instruction !== null && preset !== null) {
    throw new BadRequestException('지시문과 프리셋 중 하나만 보냅니다');
  }
  if (instruction === null && preset === null) {
    throw new BadRequestException('지시문이나 프리셋이 필요합니다');
  }
  if (instruction !== null && instruction.length === 0) {
    throw new BadRequestException('지시문이 비었습니다');
  }
  if (instruction !== null && instruction.length > MAX_INSTRUCTION) {
    throw new BadRequestException(`지시문은 ${MAX_INSTRUCTION}자까지입니다`);
  }

  const { channelId = null, messageIds = null, repoId = null } = dto.context ?? {};

  // 패널은 늘 어떤 자리에서 열린다. 근거 없는 일반 질문은 받지 않는다 (D5).
  if (channelId === null && repoId === null) {
    throw new BadRequestException('대화나 저장소 중 하나는 있어야 합니다');
  }
  if (messageIds !== null && channelId === null) {
    throw new BadRequestException('메시지를 고르면 채널도 함께 보냅니다');
  }
  if (messageIds !== null && messageIds.length === 0) {
    throw new BadRequestException('메시지를 한 개 이상 골라야 합니다');
  }
  if (messageIds !== null && messageIds.length > MAX_TRANSCRIPT_MESSAGES) {
    throw new BadRequestException(`한 번에 ${MAX_TRANSCRIPT_MESSAGES}개까지 고를 수 있습니다`);
  }
  // 요약 · 이슈 초안은 대화를 재료로 한다. 코드만으로 만들면 지어낸다.
  if (preset !== null && channelId === null) {
    throw new BadRequestException('이 프리셋은 대화가 필요합니다');
  }

  return {
    instruction,
    preset,
    channelId,
    // 중복은 접는다. 상한은 위에서 원본 길이로 봤으므로 우회 통로가 아니다.
    messageIds: messageIds === null ? null : [...new Set(messageIds)],
    repoId,
  };
}
