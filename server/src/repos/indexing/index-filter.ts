/**
 * 인덱싱할 파일의 크기 상한.
 *
 * 열람의 512KB(`MAX_BLOB_BYTES`)보다 낮은 이유는 **목적이 달라서다.** 열람은
 * 사람이 한 번 보고 마는 것이지만, 512KB 짜리 한 파일은 약 260개 청크가 되어
 * 임베딩 비용이 파일 하나에 몰린다 (설계 §3).
 *
 * 재귀 트리가 크기를 먼저 주므로 **요청을 쓰지 않고 걸러진다.**
 */
export const MAX_INDEX_BYTES = 256 * 1024;

export function isTooLarge(size: number): boolean {
  return size > MAX_INDEX_BYTES;
}

/** 표시를 찾아볼 줄 수. 더 내려가면 본문에 그 말이 나오는 글까지 버린다. */
const GENERATED_SCAN_LINES = 2;

/**
 * 코드 생성기가 쓴 파일인가.
 *
 * **경로 목록을 만들지 않는다** — 목록은 유지 비용이 끝없이 늘고, 목록에 없는
 * 것이 나올 때마다 고쳐야 한다(`blob-content.ts` 가 바이너리 판별에서 한 판단).
 * 대신 **내용**으로 본다. 생성 파일은 대개 스스로를 표시한다.
 *
 * 이 저장소에서 `.freezed.dart` · `.g.dart` 가 실제로 그 줄로 시작하고,
 * **18,182줄(전체의 18%)** 이 여기서 빠진다. 사람이 쓰지 않은 코드는 AI 근거
 * 로도 값이 없다.
 */
export function isGenerated(text: string): boolean {
  const head = text.split('\n', GENERATED_SCAN_LINES).join('\n').toUpperCase();
  return head.includes('GENERATED CODE') || head.includes('@GENERATED');
}

/**
 * 확장자 → 언어. **모르면 `null` 이다.**
 *
 * 지금은 표시용이고, 언어로 좁힌 검색이 필요해지면 그때 쓴다. 목록에 없는
 * 확장자가 나와도 인덱싱은 그대로 된다 — 이 값은 거르는 데 쓰이지 않는다.
 */
const LANGS: Record<string, string> = {
  ts: 'typescript',
  tsx: 'typescript',
  js: 'javascript',
  mjs: 'javascript',
  jsx: 'javascript',
  dart: 'dart',
  py: 'python',
  java: 'java',
  kt: 'kotlin',
  swift: 'swift',
  go: 'go',
  rs: 'rust',
  rb: 'ruby',
  php: 'php',
  cs: 'csharp',
  c: 'c',
  h: 'c',
  cpp: 'cpp',
  hpp: 'cpp',
  cc: 'cpp',
  sql: 'sql',
  sh: 'shell',
  ps1: 'powershell',
  html: 'html',
  css: 'css',
  scss: 'scss',
  json: 'json',
  yaml: 'yaml',
  yml: 'yaml',
  xml: 'xml',
  toml: 'toml',
  md: 'markdown',
  prisma: 'prisma',
};

export function langOf(path: string): string | null {
  const name = path.slice(path.lastIndexOf('/') + 1);
  const dot = name.lastIndexOf('.');
  // 점이 없거나 맨 앞이면(`.gitignore`) 확장자가 아니다.
  if (dot <= 0) return null;
  return LANGS[name.slice(dot + 1).toLowerCase()] ?? null;
}
