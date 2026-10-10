/**
 * 낱말 검색 · 결과 합치기 (RAG 강화, 2026-10-10).
 *
 * **왜 벡터 검색 하나로 두지 않나.** 코드에 대해 묻는 질문은 식별자
 * (`searchBlocker`, `CHUNK_MAX_CHARS`)나 파일 이름을 그대로 담는 일이 잦은데,
 * 임베딩은 그런 드문 낱말을 뜻으로 뭉개 버린다 — 정확히 그 낱말이 든 청크가
 * 순위 밖으로 밀린다. 거꾸로 낱말 검색은 말을 바꿔 물으면 못 찾는다. 둘의
 * 실패가 겹치지 않아 순위를 합치면 서로를 메운다(`fuseRankings`).
 *
 * 문서 쪽 낱말은 DB 가 만든다 — `repo_index_chunks.search_tsv` 생성 컬럼
 * (마이그레이션 `20261010000000_index_chunks_search_tsv`). 여기는 **질의 쪽**만
 * 다룬다. 두 쪽이 같은 규칙으로 쪼개야 맞는다: 식별자는 통째 + 낙타 표기 ·
 * 밑줄로 나눈 조각, 경로는 `/ . -` 로 나눈 조각.
 */

/** 질의에서 쓸 낱말 수 상한. 대화 끝 2,000자를 검색어로 쓰는 프리셋 경로가 있다. */
export const MAX_QUERY_TERMS = 32;

/**
 * 한국어 낱말 끝에서 떼어 낼 조사 · 어미. **긴 것부터 본다** — `에서` 를
 * `서` 보다 먼저 떼야 한다.
 *
 * 형태소 분석기를 들이지 않았다(§3 판단 8). 질의 쪽에서 끝을 떼고 문서 쪽은
 * 앞부분 일치(`:*`)로 찾으면 `인덱싱이` 로 물어도 `인덱싱을` 이 든 청크가
 * 걸린다 — 문서 쪽은 손대지 않아도 된다.
 */
const KO_ENDINGS = [
  '으로부터',
  '에서부터',
  '이라도',
  '하려면',
  '되려면',
  '했는데',
  '하는데',
  '인가요',
  '하나요',
  '되나요',
  '했나요',
  '할까요',
  '나가나',
  '인지',
  '는지',
  '은지',
  '할까',
  '하면',
  '되면',
  '이면',
  '으면',
  '해서',
  '아서',
  '어서',
  '하고',
  '하는',
  '되는',
  '했다',
  '한다',
  '된다',
  '해요',
  '에서',
  '으로',
  '에게',
  '까지',
  '마다',
  '부터',
  '처럼',
  '보다',
  '이나',
  '라는',
  '이란',
  '란',
  '이고',
  '되나',
  '하나',
  '은',
  '는',
  '이',
  '가',
  '을',
  '를',
  '에',
  '의',
  '로',
  '와',
  '과',
  '도',
  '만',
  '씩',
  '일',
  '나',
  '해',
  '한',
  '된',
  '할',
  '될',
  '야',
  '요',
];

/**
 * 질문에만 있고 코드 · 문서의 뜻과 상관없는 낱말. 남겨 두면 흔하지 않아
 * IDF 가 높게 나와(주석에 「어디」는 드물다) 엉뚱한 청크를 끌어올린다.
 */
const STOP_WORDS = new Set([
  // 한국어 — 끝을 뗀 뒤의 모양으로 적는다
  '어디',
  '어디서',
  '어떻게',
  '어떤',
  '무엇',
  '뭐',
  '왜',
  '언제',
  '어느',
  '있',
  '없',
  '어떻',
  '알려',
  '알려줘',
  '설명',
  '설명해',
  '보여',
  '보여줘',
  '코드',
  '부분',
  '곳',
  '거',
  '것',
  '좀',
  '그',
  '이거',
  '저',
  '수',
  '때',
  '있나',
  '있어',
  '없어',
  '돼',
  '되',
  '곳은',
  '곳이',
  '방법',
  '몇',
  '번',
  '다시',
  '하나',
  // 영어
  'the',
  'a',
  'an',
  'is',
  'are',
  'was',
  'be',
  'to',
  'of',
  'in',
  'on',
  'for',
  'and',
  'or',
  'how',
  'what',
  'where',
  'why',
  'when',
  'which',
  'does',
  'do',
  'it',
  'this',
  'that',
  'with',
  'from',
  'by',
  'as',
  'at',
  'can',
  'code',
]);

const HANGUL = /[ㄱ-ㆎ가-힣]/;

function stripKoreanEnding(word: string): string {
  for (const end of KO_ENDINGS) {
    // 떼고 남는 줄기가 두 글자 이상일 때만 뗀다 — `사이` 에서 `이` 를 떼면
    // 한 글자 `사` 가 남아 아무 데나 걸린다.
    if (word.length - end.length >= 2 && word.endsWith(end)) {
      return word.slice(0, -end.length);
    }
  }
  return word;
}

/** `searchBlocker` → `search` · `blocker`, `CHUNK_MAX_CHARS` → `chunk` · `max` · `chars`. */
function identifierParts(word: string): string[] {
  return word
    .replace(/([a-z0-9])([A-Z])/g, '$1 $2')
    .replace(/([A-Z]+)([A-Z][a-z])/g, '$1 $2')
    .split(/[\s_]+/)
    .map((p) => p.toLowerCase())
    .filter((p) => p.length >= 2);
}

/**
 * 질의 → 낱말 목록. 각 낱말은 `[\p{L}\p{N}]` 만 담는다 — `to_tsquery` 문법
 * 문자(`& | ! : * ( )`)가 섞일 수 없어 그대로 넣어도 된다.
 *
 * 순서를 지키고 겹침을 뺀다. 결정적이어야 같은 질문이 같은 순위를 낸다.
 */
export function queryTermsOf(query: string): string[] {
  const out: string[] = [];
  const seen = new Set<string>();
  const push = (t: string) => {
    if (t.length < 2 || STOP_WORDS.has(t) || seen.has(t)) return;
    seen.add(t);
    out.push(t);
  };

  for (const raw of query.match(/[\p{L}\p{N}_]+/gu) ?? []) {
    // `Redis를` 처럼 한글과 영문이 붙은 낱말은 글자 종류가 바뀌는 곳에서 나눈다.
    for (const run of raw.match(/[ㄱ-ㆎ가-힣]+|[^ㄱ-ㆎ가-힣]+/g) ?? []) {
      if (HANGUL.test(run)) {
        // 끝을 떼기 전 모양도 불용어로 본다 — `곳은` 은 줄기가 한 글자라 떼지 않는다.
        if (!STOP_WORDS.has(run)) push(stripKoreanEnding(run));
      } else {
        const whole = run.toLowerCase();
        // 낙타 표기는 통째 낱말과 조각을 함께 넣는다 — 문서 쪽 생성 컬럼도 둘 다
        // 담는다. 통째로 맞으면 조각까지 맞아 점수가 쌓이므로 정확히 그 식별자가
        // 든 청크가 조각만 맞는 청크보다 위로 간다.
        // **밑줄이 든 낱말은 통째를 넣지 않는다** — Postgres 파서가 문서 쪽에서
        // `_` 를 구분자로 보아 `chunk_max` 라는 낱말이 아예 생기지 않는다.
        const parts = identifierParts(run);
        if (!run.includes('_') && (parts.length !== 1 || parts[0] !== whole)) push(whole);
        for (const p of parts) push(p);
      }
      if (out.length >= MAX_QUERY_TERMS) return out;
    }
  }
  return out;
}

/**
 * 낱말 하나의 `to_tsquery` 식. 세 글자 이상은 앞부분 일치(`:*`)다 — 한국어
 * 끝을 뗀 줄기가 `검색을` · `검색이` 에 함께 걸리고, 영어는 `index` 가
 * `indexing` 에 걸린다. 두 글자 영어는 앞부분이 너무 많이 걸려(`id` →
 * `identifier` · `idle` …) 정확히 맞을 때만 친다.
 */
export function tsQueryOf(term: string): string {
  if (HANGUL.test(term) || term.length >= 3) return `${term}:*`;
  return term;
}

/**
 * RRF 상수. 원 논문(Cormack 2009)의 60 을 쓴다 — 순위가 낮은 쪽의 차이를
 * 눌러 한쪽 목록의 1위가 다른 쪽 목록을 통째로 이기지 못하게 한다.
 */
export const RRF_K = 60;

/**
 * 질문에 코드 식별자가 있는가 — 낙타 표기(`searchBlocker`), 밑줄
 * (`CHUNK_MAX_CHARS`), 파일 이름(`chunker.ts`), 경로(`src/ai`). `GitHub` 같은
 * 고유명사 하나로는 치지 않는다(대문자로 시작해 소문자 뒤 대문자가 한 번 —
 * 이것도 낙타 표기라 걸린다. 걸려도 낱말 갈래를 온전히 믿을 뿐 해롭지 않다).
 */
export function hasIdentifier(query: string): boolean {
  return /[a-z0-9][A-Z]|[A-Za-z0-9]_[A-Za-z0-9]|\w\.[a-z]{1,5}\b|\w\/\w/.test(query);
}

/**
 * 낱말 갈래의 RRF 가중치. **식별자가 없는 질문(대개 한국어 서술)은 0.5** 다.
 *
 * 이유: 한국어 서술 질문에서 낱말 갈래는 같은 낱말을 더 많이 담은 설계 문서
 * 청크를 끌어올린다(평가에서 낱말 갈래 한국어 MRR 0.233). 그런 질문의 뜻은
 * 벡터 갈래가 맡는다. 0.5 면 **낱말에만 있는 청크(최대 0.5/61)가 벡터 후보
 * 30위(1/90)보다도 낮아** 결과가 벡터 후보 안에서만 나온다 — 낱말은 벡터
 * 후보의 **순서만** 고친다. 진짜 임베딩으로 재기 전에 벡터 하나일 때보다
 * 크게 나빠지지 않게 하는 안전장치다(`HYBRID_CANDIDATES` 가 61 을 넘으면
 * 이 보장이 깨진다 — 테스트가 지킨다).
 *
 * 식별자가 있으면 1 — 낱말 갈래가 확실히 이기는 질문이다(식별자 MRR 0.713).
 */
export const PROSE_LEXICAL_WEIGHT = 0.5;

export function lexicalWeightOf(query: string): number {
  return hasIdentifier(query) ? 1 : PROSE_LEXICAL_WEIGHT;
}

/**
 * 여러 순위 목록을 하나로 합친다(Reciprocal Rank Fusion). `weights` 는 목록마다
 * 곱하는 값이고 없으면 모두 1 이다.
 *
 * **점수가 아니라 순위를 합친다.** 코사인 유사도(0~1)와 IDF 합(0~수십)은
 * 단위가 달라 더하면 한쪽이 다른 쪽을 덮는다 — 순위는 단위가 없다.
 * 같은 점수면 먼저 넘긴 목록에서 더 위였던 것이 앞선다(결정적).
 */
export function fuseRankings<T extends { id: string }>(
  lists: T[][],
  limit: number,
  weights: number[] = [],
): Array<T & { fused: number }> {
  const acc = new Map<string, { item: T; fused: number; best: number }>();
  lists.forEach((list, li) => {
    const w = weights[li] ?? 1;
    list.forEach((item, rank) => {
      const add = w / (RRF_K + rank + 1);
      const prev = acc.get(item.id);
      // 앞 목록 · 높은 순위일수록 작은 값 — 동점을 가를 때 쓴다.
      const order = li * 10_000 + rank;
      if (prev) {
        prev.fused += add;
        prev.best = Math.min(prev.best, order);
      } else {
        acc.set(item.id, { item, fused: add, best: order });
      }
    });
  });
  return [...acc.values()]
    .sort((a, b) => b.fused - a.fused || a.best - b.best)
    .slice(0, limit)
    .map(({ item, fused }) => ({ ...item, fused }));
}
