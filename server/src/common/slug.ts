import { randomBytes } from 'crypto';

/**
 * 사람이 지은 이름에서 URL 식별자를 만든다.
 *
 * ASCII 밖 문자는 남길 수 없어 제거하는데, **한글 이름은 그 결과가 빈 문자열이
 * 된다.** 이 프로젝트의 채널·스페이스 이름은 대부분 한글이므로, 빈 결과를
 * 오류로 처리하면 "한글로 이름을 지으면 생성이 안 되는" 상태가 된다.
 * 그래서 비면 임의 식별자로 대체한다 — 식별자는 URL용일 뿐이고,
 * 신경 쓰는 사용자는 직접 지정할 수 있다.
 */
export function slugify(name: string, fallbackPrefix: string): string {
  const slug = name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 40);

  return slug || `${fallbackPrefix}-${randomBytes(4).toString('hex')}`;
}
