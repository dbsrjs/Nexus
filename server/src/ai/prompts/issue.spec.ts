import { issuePrompt, parseIssueDraft, MAX_ISSUE_TITLE } from './issue';

describe('issuePrompt', () => {
  const out = issuePrompt('[01:00] 가영: 로그인 버튼이 안 눌려요', '');

  it('JSON 으로 title · description 을 달라고 지시한다', () => {
    expect(out[0].content).toContain('JSON');
    expect(out[0].content).toContain('title');
    expect(out[0].content).toContain('description');
  });

  it('대화가 user 쪽에 들어가고 코드가 없으면 코드 절이 없다', () => {
    expect(out[1].content).toContain('로그인 버튼이 안 눌려요');
    expect(out[1].content).not.toContain('## 코드');
  });

  it('코드가 있으면 코드 절을 덧붙인다', () => {
    expect(issuePrompt('대화', '[1] a.ts:1-2')[1].content).toContain('## 코드\n[1] a.ts:1-2');
  });
});

describe('parseIssueDraft', () => {
  it('정상 JSON 을 읽는다', () => {
    expect(parseIssueDraft('{"title":"버튼 고침","description":"본문"}')).toEqual({
      title: '버튼 고침',
      description: '본문',
    });
  });

  it('코드펜스로 감싼 JSON 도 읽는다 — 모델이 종종 그렇게 준다', () => {
    expect(parseIssueDraft('```json\n{"title":"t","description":"d"}\n```').title).toBe('t');
  });

  it('★ JSON 이 아니면 던진다 — 러너가 fatal 로 친다', () => {
    expect(() => parseIssueDraft('제목: 버튼')).toThrow();
  });

  it('제목이 비었으면 던진다', () => {
    expect(() => parseIssueDraft('{"title":"  ","description":"d"}')).toThrow();
  });

  it('description 이 문자열이 아니면 던진다', () => {
    expect(() => parseIssueDraft('{"title":"t","description":3}')).toThrow();
  });

  it('제목이 상한을 넘으면 자른다 — 사람이 확인하는 초안이다', () => {
    const long = 'a'.repeat(MAX_ISSUE_TITLE + 5);
    expect(parseIssueDraft(JSON.stringify({ title: long, description: '' })).title).toHaveLength(
      MAX_ISSUE_TITLE,
    );
  });
});
