import { AiRunKind } from '@prisma/client';
import { LlmMessage } from '../../llm/llm.provider';
import { ChunkHit } from '../../repos/indexing/index-chunks.repository';
import { AskRequest } from '../ask-request';
import { codeSection } from '../code-context';
import { askPrompt } from './ask';
import { issuePrompt } from './issue';
import { summarizePrompt } from './summarize';

/** 프롬프트의 재료. 서비스가 적재 때와 워커 실행 때 **같은 것을** 만든다. */
export interface AskMaterial {
  /** `buildTranscript()` 결과. 대화 컨텍스트가 없으면 null */
  transcript: string | null;
  chunks: ChunkHit[];
}

export interface BuiltPrompt {
  kind: AiRunKind;
  messages: LlmMessage[];
  /** 구조화 출력(이슈 초안) */
  json: boolean;
}

/**
 * 요청 → 프롬프트. **적재(`AiService.ask`)와 실행(`loadPrompt`)이 이 하나를
 * 부른다** — 둘이 따로 조립하면 캐시 키와 실제로 보낸 프롬프트가 어긋난다.
 * 순수 함수다.
 *
 * 프리셋은 대화가 있어야 한다(`validateAskRequest` 가 이미 막았다). 그래도
 * 여기 오면 빈 대화로 조립하지 않고 던진다.
 */
export function buildAskPrompt(
  req: Pick<AskRequest, 'instruction' | 'preset'>,
  material: AskMaterial,
): BuiltPrompt {
  const code = codeSection(material.chunks);

  if (req.preset !== null) {
    if (material.transcript === null) {
      throw new Error('프리셋에 대화가 없습니다.');
    }
    if (req.preset === 'issue') {
      return {
        kind: AiRunKind.draft_issue,
        messages: issuePrompt(material.transcript, code),
        json: true,
      };
    }
    return {
      kind: AiRunKind.summarize,
      messages: summarizePrompt(material.transcript, code),
      json: false,
    };
  }

  return {
    kind: AiRunKind.ask,
    messages: askPrompt({
      transcript: material.transcript,
      code,
      instruction: req.instruction ?? '',
    }),
    json: false,
  };
}
