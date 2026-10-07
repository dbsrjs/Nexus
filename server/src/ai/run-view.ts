import { Prisma } from '@prisma/client';

/**
 * 실행 하나를 앱에 보이는 모양. `GET .../ai/runs/:runId` 와 사슬 읽기(19)가 같은 것을
 * 쓴다 — 앱이 `AiRun.fromJson` 하나로 읽게. 입력(`input`)은 싣지 않는다.
 */
export const RUN_VIEW_SELECT = {
  id: true,
  kind: true,
  state: true,
  result: true,
  error: true,
  model: true,
  fallback: true,
  parentRunId: true,
  promptTokens: true,
  completionTokens: true,
  createdAt: true,
  finishedAt: true,
} satisfies Prisma.AiRunSelect;

export type RunViewRow = Prisma.AiRunGetPayload<{ select: typeof RUN_VIEW_SELECT }>;

export function toRunView(row: RunViewRow) {
  const { id, ...rest } = row;
  return { runId: id, ...rest };
}
