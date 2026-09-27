import { LlmHttpError, LlmMessage, LlmOptions, LlmProvider, LlmResult } from './llm.provider';
import { createHash } from 'node:crypto';

/**
 * 실패 주입 지시문. 프롬프트 어디에 있어도 된다 — 계약 검증은 자유 지시문에 넣는다.
 *
 * | 지시문 | 동작 |
 * |---|---|
 * | `[[fake-llm:status=503;times=2]]` | 처음 두 번 `LlmHttpError(503)`, 그 뒤 성공 |
 * | `[[fake-llm:status=503]]` | 매번 503 (`times` 가 없으면 끝없이) |
 * | `[[fake-llm:status=429;retry-after=0;times=6]]` | 429 + `Retry-After: 0` |
 * | `[[fake-llm:status=400]]` | 4xx — 러너가 곧바로 포기한다 |
 * | `[[fake-llm:empty]]` · `[[fake-llm:truncated]]` | 빈 답 · 잘린 답 |
 *
 * **왜 있나** — 이것이 없을 때 fake 는 늘 즉시 성공해 큐의 재시도 · 소진 · 포기
 * 갈래를 계약 검증이 한 번도 태우지 못했다(13-1 빚, 2026-09-27 해소).
 */
const DIRECTIVE = /\[\[fake-llm:([^\]]*)\]\]/;

interface Directive {
  status?: number;
  retryAfterSec?: number;
  /** 몇 번 실패하나. 없으면 끝없이. */
  times?: number;
  empty?: boolean;
  truncated?: boolean;
}

/**
 * **모르는 지시는 던진다.** 오타(`stauts`)를 무시하면 성공 응답이 나가고,
 * 실패를 기대한 계약 검증이 엉뚱한 이유로 실패하거나 거짓으로 통과한다.
 */
function parseDirective(raw: string): Directive {
  const out: Directive = {};
  for (const part of raw.split(';').map((p) => p.trim()).filter(Boolean)) {
    const [key, value] = part.split('=').map((s) => s.trim());
    if (key === 'empty' && value === undefined) out.empty = true;
    else if (key === 'truncated' && value === undefined) out.truncated = true;
    else if (key === 'status' && /^\d{3}$/.test(value ?? '')) out.status = Number(value);
    else if (key === 'times' && /^\d+$/.test(value ?? '')) out.times = Number(value);
    else if (key === 'retry-after' && /^\d+$/.test(value ?? '')) out.retryAfterSec = Number(value);
    else throw new Error(`fake-llm 지시문을 읽을 수 없습니다: "${part}"`);
  }
  return out;
}

/**
 * 계약 검증용. **결정적이어야 한다** — 같은 입력에 같은 출력을 주지 않으면
 * `promptHash` 캐시 적중을 검증할 수 없다 (설계 §12).
 *
 * 내용은 쓸모없어도 된다. 이 어댑터로는 프롬프트가 실제로 쓸모 있는지 알 수
 * 없고, 그것은 실제 태우기가 볼 몫이다.
 */
export class FakeLlmProvider implements LlmProvider {
  readonly modelId = 'fake:fake';

  /**
   * 실패 주입 지시문이 있는 프롬프트마다 몇 번 불렸나. 큐의 재시도는 같은
   * 프롬프트를 다시 부르므로 이 수가 곧 시도 횟수다. 지시문이 없는 프롬프트는
   * 세지 않는다 — 평소에는 아무것도 쌓이지 않는다.
   */
  private readonly calls = new Map<string, number>();

  /**
   * 기본값 8192 는 `LLM_MAX_TOKENS` 미설정 시의 기본값(`llm.config.ts`)과
   * 맞춘 것뿐이다 — `LlmModule` 은 실제 설정값을 그대로 넘긴다.
   */
  constructor(readonly maxTokens: number = 8192) {}

  complete(messages: LlmMessage[], options: LlmOptions): Promise<LlmResult> {
    const joined = messages.map((m) => `${m.role}:${m.content}`).join('\n');
    const digest = createHash('sha256').update(joined).digest('hex').slice(0, 16);

    const found = DIRECTIVE.exec(joined);
    let directive: Directive | null = null;
    try {
      directive = found ? parseDirective(found[1]) : null;
    } catch (err) {
      return Promise.reject(err as Error);
    }

    if (directive?.status != null) {
      const n = (this.calls.get(digest) ?? 0) + 1;
      this.calls.set(digest, n);
      if (directive.times == null || n <= directive.times) {
        return Promise.reject(
          new LlmHttpError(
            `fake-llm 이 ${directive.status} 를 주었습니다 (${n}번째)`,
            directive.status,
            directive.retryAfterSec,
          ),
        );
      }
    }

    const text = directive?.empty
      ? ''
      : options.json
        ? JSON.stringify({
            title: `가짜 제목 ${digest}`,
            description: joined.slice(0, 200),
            labelIds: [],
          })
        : `가짜 요약 ${digest}\n\n입력 ${messages.length}줄을 받았습니다.`;

    return Promise.resolve({
      text,
      // 센 척하지 않는다 (판단 #2).
      promptTokens: null,
      completionTokens: null,
      model: 'fake',
      truncated: directive?.truncated === true,
      fallback: false,
    });
  }
}
