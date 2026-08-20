import { formatIssueKey, issueKeyPrefix } from './issue-key';

/**
 * 이슈 키는 사람이 대화에서 부르는 이름이다("NEXUS-12 고쳤어").
 * 스페이스 slug 는 불변이므로 한 스페이스 안에서 접두사가 섞이지 않는다.
 */
describe('issueKeyPrefix', () => {
  it('한 마디 slug 는 그대로 대문자가 된다', () => {
    expect(issueKeyPrefix('nexus')).toBe('NEXUS');
  });

  it('첫 마디가 짧으면 다음 마디를 이어 붙인다', () => {
    // 'my' 만으로는 무엇의 키인지 읽히지 않는다.
    expect(issueKeyPrefix('my-cool-project')).toBe('MYCOOL');
  });

  it('6자를 넘지 않는다', () => {
    expect(issueKeyPrefix('supercalifragilistic')).toBe('SUPERC');
  });

  it('한글 이름의 폴백 slug 도 읽을 수 있는 접두사가 된다', () => {
    // slugify() 는 한글 이름에서 'space-a1b2c3d4' 같은 폴백을 만든다.
    expect(issueKeyPrefix('space-a1b2c3d4')).toBe('SPACE');
  });

  it('영숫자가 하나도 없으면 ISSUE 로 떨어진다', () => {
    expect(issueKeyPrefix('---')).toBe('ISSUE');
    expect(issueKeyPrefix('')).toBe('ISSUE');
  });
});

describe('formatIssueKey', () => {
  it('접두사와 연번을 붙인다', () => {
    expect(formatIssueKey('nexus', 12)).toBe('NEXUS-12');
  });
});
