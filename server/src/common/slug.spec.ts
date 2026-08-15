import { slugify } from './slug';

/**
 * 이 테스트는 **실제로 겪은 버그**에서 나왔다.
 *
 * 처음 구현은 ASCII 밖 문자를 제거한 뒤 빈 문자열이면 오류를 냈다. 그 결과
 * 한글 이름으로는 채널 생성이 항상 409, 스페이스 생성이 400 이었다 —
 * 이 프로젝트의 이름은 대부분 한글이므로 사실상 상시 실패 경로였다.
 * 화면으로는 "가끔 생성이 안 된다" 로만 보여 놓치기 쉬웠다.
 */
describe('slugify', () => {
  it('영문 이름은 소문자 하이픈 형태로 바꾼다', () => {
    expect(slugify('Design Review', 'channel')).toBe('design-review');
    expect(slugify('  Hello   World  ', 'channel')).toBe('hello-world');
  });

  it('앞뒤 하이픈을 남기지 않는다', () => {
    expect(slugify('!!! hello !!!', 'channel')).toBe('hello');
  });

  it('한글 이름이어도 실패하지 않고 대체 식별자를 만든다', () => {
    const slug = slugify('새 채널', 'channel');
    expect(slug).toMatch(/^channel-[0-9a-f]{8}$/);
  });

  it('대체 식별자는 호출마다 다르다 — 연속 생성이 충돌하지 않는다', () => {
    const a = slugify('회의록', 'channel');
    const b = slugify('회의록', 'channel');
    expect(a).not.toBe(b);
  });

  it('접두사로 어느 쪽에서 만든 식별자인지 구분한다', () => {
    expect(slugify('공간', 'space')).toMatch(/^space-/);
    expect(slugify('채널', 'channel')).toMatch(/^channel-/);
  });

  it('40자를 넘기지 않는다 — DB 컬럼과 URL 길이를 지킨다', () => {
    const long = 'a'.repeat(100);
    expect(slugify(long, 'channel').length).toBeLessThanOrEqual(40);
  });
});
