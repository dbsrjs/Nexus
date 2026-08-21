import { ConfigService } from '@nestjs/config';

/**
 * **GitHub 서버가 오는 주소**다. 콜백(`GITHUB_CALLBACK_URL`)과 다르다 —
 * 콜백은 사람의 브라우저가 오므로 localhost 로 충분하지만, 웹훅은 밖에서
 * 닿아야 하므로 터널이어야 한다. 합치면 OAuth 를 시험하는 데도 터널이
 * 필요해진다 (설계 §8).
 *
 * 미설정이면 자동 등록만 400 이고 수동 등록(10-1)은 그대로 된다.
 */
export function resolvePublicBaseUrl(config: ConfigService): string | null {
  // 빈 문자열을 미설정으로 친다. `??` 로 두면 `.env` 에 자리만 잡아 둔 값이
  // 통과한다 — 8-1 에서 STORAGE_LOCAL_DIR 로 겪었다.
  const raw = (config.get<string>('PUBLIC_BASE_URL') || '').trim();
  if (!raw) return null;

  // 훅 URL 로 쓸 수 없는 값은 아예 없는 것으로 친다. GitHub 이 422 로
  // 거절하는 것보다 우리가 400 으로 안내하는 편이 낫다.
  if (!/^https?:\/\//.test(raw)) return null;

  // 끝 슬래시를 떼지 않으면 `{base}/api/...` 가 `//api` 가 된다.
  return raw.replace(/\/+$/, '');
}
