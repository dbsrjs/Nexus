import { confirmPage, escapeHtml, maskEmail } from './callback-page';

describe('callback-page — 연결 확인 화면', () => {
  it('★ 이름 · code · state 를 이스케이프한다 — 전부 사용자 입력이다', () => {
    const html = confirmPage(
      { name: '<script>alert(1)</script>', email: 'ab@x.io' },
      '"><img src=x>',
      "a'b",
    );
    expect(html).not.toContain('<script>alert');
    expect(html).not.toContain('"><img');
    expect(html).toContain('&lt;script&gt;');
    expect(html).toContain('value="&quot;&gt;&lt;img src=x&gt;"');
    expect(html).toContain('value="a&#39;b"');
  });

  it('폼은 같은 경로로 POST 한다 — GET 은 연결하지 않는다', () => {
    const html = confirmPage({ name: 'A', email: 'a@x.io' }, 'c', 's');
    expect(html).toContain('<form method="post" action="callback">');
  });

  it('이메일은 알아볼 만큼만 보인다', () => {
    expect(maskEmail('dbsrjs1224@gmail.com')).toBe('db***@gmail.com');
    expect(maskEmail('a@x.io')).toBe('a***@x.io');
    expect(maskEmail('broken')).toBe('***');
  });

  it('escapeHtml 은 & 를 먼저 바꾼다 — 두 번 이스케이프되지 않는다', () => {
    expect(escapeHtml('&lt;')).toBe('&amp;lt;');
  });
});
