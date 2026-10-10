import { HYBRID_CANDIDATES } from './index-chunks.repository';
import {
  MAX_QUERY_TERMS,
  PROSE_LEXICAL_WEIGHT,
  RRF_K,
  fuseRankings,
  hasIdentifier,
  lexicalWeightOf,
  queryTermsOf,
  tsQueryOf,
} from './lexical';

describe('queryTermsOf', () => {
  it('낙타 표기는 통째 낱말과 조각을 함께 낸다 — 문서 쪽 생성 컬럼과 같은 규칙', () => {
    expect(queryTermsOf('searchBlocker')).toEqual(['searchblocker', 'search', 'blocker']);
  });

  it('밑줄 식별자는 조각만 낸다 — Postgres 파서가 문서 쪽에서 _ 를 구분자로 본다', () => {
    expect(queryTermsOf('CHUNK_MAX_CHARS')).toEqual(['chunk', 'max', 'chars']);
  });

  it('한국어는 조사 · 어미를 뗀다 — 앞부분 일치로 다른 조사가 붙은 문서에 걸린다', () => {
    expect(queryTermsOf('인덱싱이 실패하면')).toEqual(['인덱싱', '실패']);
    expect(queryTermsOf('토큰을 암호화해서')).toEqual(['토큰', '암호화']);
  });

  it('떼고 남는 줄기가 한 글자면 떼지 않는다 — 한 글자 앞부분은 아무 데나 걸린다', () => {
    expect(queryTermsOf('사이')).toEqual(['사이']);
  });

  it('질문에만 있는 낱말(어디 · 어떻게 · how)은 버린다', () => {
    expect(queryTermsOf('웹훅 서명은 어디서 어떻게 검증해')).toEqual([
      '웹훅',
      '서명',
      '검증',
    ]);
    expect(queryTermsOf('how is the token rotated')).toEqual(['token', 'rotated']);
  });

  it('한글과 영문이 붙은 낱말은 글자 종류가 바뀌는 곳에서 나눈다', () => {
    expect(queryTermsOf('Redis를 붙인다')).toEqual(['redis', '붙인다']);
  });

  it('겹침을 빼고 순서를 지킨다 — 같은 질문이 같은 순위를 내야 한다', () => {
    expect(queryTermsOf('검색 검색을 search')).toEqual(['검색', 'search']);
  });

  it('tsquery 문법 문자가 낱말에 들어가지 않는다', () => {
    for (const t of queryTermsOf("a|b & c:* !d (e) 'f' 검색:*")) {
      expect(t).toMatch(/^[\p{L}\p{N}]+$/u);
    }
  });

  it('낱말 수에 상한이 있다 — 대화 끝 2,000자가 검색어가 되는 경로가 있다', () => {
    const many = Array.from({ length: 100 }, (_, i) => `word${i}`).join(' ');
    expect(queryTermsOf(many)).toHaveLength(MAX_QUERY_TERMS);
  });

  it('낱말이 없으면 빈 목록이다(낱말 갈래를 건너뛴다)', () => {
    expect(queryTermsOf('?? !! ...')).toEqual([]);
    expect(queryTermsOf('어디 어떻게')).toEqual([]);
  });
});

describe('tsQueryOf', () => {
  it('한국어와 세 글자 이상은 앞부분 일치다', () => {
    expect(tsQueryOf('검색')).toBe('검색:*');
    expect(tsQueryOf('index')).toBe('index:*');
  });

  it('두 글자 영어는 정확히 맞을 때만 — id 가 identifier 에 걸리지 않게', () => {
    expect(tsQueryOf('id')).toBe('id');
  });
});

describe('fuseRankings', () => {
  const item = (id: string) => ({ id });

  it('두 목록에 다 있는 것이 한쪽 1위보다 앞선다', () => {
    const fused = fuseRankings(
      [
        [item('a'), item('b')],
        [item('c'), item('b')],
      ],
      3,
    );
    expect(fused.map((f) => f.id)).toEqual(['b', 'a', 'c']);
    expect(fused[0].fused).toBeCloseTo(2 / (RRF_K + 2));
  });

  it('동점이면 앞 목록에서 위였던 것이 앞선다 — 결정적이어야 한다', () => {
    const fused = fuseRankings([[item('a')], [item('c')]], 2);
    expect(fused.map((f) => f.id)).toEqual(['a', 'c']);
  });

  it('상한만큼만 남기고, 빈 목록은 다른 목록을 그대로 둔다', () => {
    expect(
      fuseRankings([[item('a'), item('b'), item('c')], []], 2).map((f) => f.id),
    ).toEqual(['a', 'b']);
  });

  it('원래 필드를 지킨다', () => {
    const [top] = fuseRankings([[{ id: 'a', path: 'x.ts' }]], 1);
    expect(top.path).toBe('x.ts');
  });
});

describe('hasIdentifier · lexicalWeightOf', () => {
  it('낙타 표기 · 밑줄 · 파일 이름 · 경로는 식별자다', () => {
    for (const q of ['fooBar 가 뭐야', 'MAX_SIZE', 'main.ts 에서', 'lib/core 아래']) {
      expect(hasIdentifier(q)).toBe(true);
      expect(lexicalWeightOf(q)).toBe(1);
    }
  });

  it('한국어 서술 질문은 식별자가 아니다 — 낱말 갈래를 반만 믿는다', () => {
    for (const q of [
      '로그아웃하면 세션은 어떻게 되나요?',
      'AI 답은 몇 줄까지',
      'Redis cache',
    ]) {
      expect(hasIdentifier(q)).toBe(false);
      expect(lexicalWeightOf(q)).toBe(PROSE_LEXICAL_WEIGHT);
    }
  });

  it('★ 가중치 0.5 면 낱말에만 있는 청크는 결과에 들지 못한다 — 벡터 후보의 순서만 바뀐다', () => {
    const vector = Array.from({ length: HYBRID_CANDIDATES }, (_, i) => ({ id: `v${i}` }));
    // 낱말 갈래 1~8위가 전부 벡터 후보 밖에 있는 최악의 경우.
    const words = Array.from({ length: HYBRID_CANDIDATES }, (_, i) => ({ id: `w${i}` }));
    const fused = fuseRankings([vector, words], 20, [1, PROSE_LEXICAL_WEIGHT]);
    expect(fused).toHaveLength(20);
    expect(fused.every((f) => f.id.startsWith('v'))).toBe(true);
  });

  it('그 보장이 서는 후보 수 — 벡터 마지막 후보가 낱말 1위(0.5/61)보다 높아야 한다', () => {
    expect(1 / (RRF_K + HYBRID_CANDIDATES)).toBeGreaterThan(
      PROSE_LEXICAL_WEIGHT / (RRF_K + 1),
    );
  });

  it('가중치 1 이면 낱말 1위가 벡터 하위를 밀어낸다(식별자 질문)', () => {
    const vector = Array.from({ length: HYBRID_CANDIDATES }, (_, i) => ({ id: `v${i}` }));
    const fused = fuseRankings([vector, [{ id: 'w0' }]], 8, [1, 1]);
    expect(fused.map((f) => f.id)).toContain('w0');
  });
});
