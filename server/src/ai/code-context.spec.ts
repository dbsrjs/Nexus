import { citationsOf, codeSection } from './code-context';
import { ChunkHit } from '../repos/indexing/index-chunks.repository';

const chunk = (over: Partial<ChunkHit> = {}): ChunkHit => ({
  id: 'k-1',
  path: 'lib/socket.dart',
  lang: 'dart',
  startLine: 1,
  endLine: 6,
  content: 'class A {}',
  commitSha: 'abc',
  score: 0.5,
  ...over,
});

describe('codeSection', () => {
  it('청크가 없으면 빈 문자열이다 — 절을 싣지 않는다', () => {
    expect(codeSection([])).toBe('');
  });

  it('[n] 경로:시작-끝 머리말과 언어 펜스로 싼다', () => {
    expect(codeSection([chunk()])).toBe('[1] lib/socket.dart:1-6\n```dart\nclass A {}\n```');
  });

  it('번호는 1부터 순서대로다 — 인용 번호가 여기에 묶인다', () => {
    const out = codeSection([chunk(), chunk({ id: 'k-2', path: 'b.ts', lang: null })]);
    expect(out).toContain('[1] lib/socket.dart');
    expect(out).toContain('[2] b.ts:1-6\n```\n');
  });

  it('★ 본문에 백틱 셋이 있으면 펜스를 더 길게 — 청크가 절을 깨뜨리지 않는다', () => {
    const out = codeSection([chunk({ lang: 'md', content: '```ts\nx\n```' })]);
    expect(out.startsWith('[1] lib/socket.dart:1-6\n````md\n')).toBe(true);
    expect(out.endsWith('\n````')).toBe(true);
  });
});

describe('citationsOf', () => {
  it('★ 인용은 우리가 넣은 청크에서만 나온다', () => {
    expect(citationsOf([chunk(), chunk({ id: 'k-2', path: 'b.ts', startLine: 9, endLine: 12 })])).toEqual([
      { n: 1, path: 'lib/socket.dart', startLine: 1, endLine: 6, commitSha: 'abc' },
      { n: 2, path: 'b.ts', startLine: 9, endLine: 12, commitSha: 'abc' },
    ]);
  });
});
