import { dmKey, dmPeerOf } from './dm-key';

describe('dmKey', () => {
  it('순서와 무관하게 같은 key', () => {
    expect(dmKey('b', 'a')).toBe('dm:a:b');
    expect(dmKey('a', 'b')).toBe('dm:a:b');
  });

  it('★ 사람이 만드는 채널 key 규칙(소문자 · 숫자 · 하이픈)과 겹치지 않는다', () => {
    expect(/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(dmKey('a', 'b'))).toBe(false);
  });
});

describe('dmPeerOf', () => {
  it('나 아닌 쪽을 준다', () => {
    expect(dmPeerOf('dm:a:b', 'a')).toBe('b');
    expect(dmPeerOf('dm:a:b', 'b')).toBe('a');
  });

  it('내가 없거나 DM key 가 아니면 null', () => {
    expect(dmPeerOf('dm:a:b', 'c')).toBeNull();
    expect(dmPeerOf('general', 'a')).toBeNull();
  });
});
