/// 조사 고르기 — 받침에 따라 「을/를」 · 「이/가」 · 「으로/로」(2026-10-10 UI/UX 검토).
///
/// 이름 · 키 같은 바뀌는 낱말 뒤에 조사를 붙일 때, 받침을 몰라 「#일반 에」 · 「GitHub 을」 처럼
/// 띄어 쓰던 곳을 붙여 쓰려고 둔다. 띄어 쓴 조사는 번역체로 읽힌다.
///
/// 한글이 아닌 끝은 **읽는 소리**로 본다 — 숫자는 한국어로(1 일 · 2 이 …), 영문 대문자 하나는
/// 알파벳 이름으로(L 엘 · M 엠 · N 엔 · R 알), 그 밖의 영문은 끝 글자가 l · m · n · ng 면 받침이
/// 있다고 본다(GitHub → 깃허브 → 「를」). 영어 낱말의 발음은 규칙으로 다 맞힐 수 없어 흔한
/// 경우만 맞춘다 — 틀려도 뜻은 전해진다.
library;

/// 받침이 있는가. 모르면(기호로 끝남) 있다고 본다 — 「을」 · 「이」 가 더 흔히 어울린다.
bool hasFinalConsonant(String word) => _final(word) != _Final.none;

/// [word] 뒤에 받침에 맞는 조사를 붙인다. `withJosa('스프린트 3', '을', '를')` → `스프린트 3을`.
String withJosa(String word, String afterConsonant, String afterVowel) =>
    '$word${hasFinalConsonant(word) ? afterConsonant : afterVowel}';

/// 「으로/로」 — ㄹ 받침 뒤에는 「로」다(서울로).
String withRo(String word) =>
    '$word${_final(word) == _Final.other ? '으로' : '로'}';

enum _Final { none, rieul, other }

_Final _final(String word) {
  final trimmed = word.trimRight();
  if (trimmed.isEmpty) return _Final.other;
  final code = trimmed.runes.last;

  // 한글 음절: (code - 0xAC00) % 28 이 종성 번호. 0 이면 받침 없음, 8 이면 ㄹ.
  if (code >= 0xAC00 && code <= 0xD7A3) {
    final jong = (code - 0xAC00) % 28;
    if (jong == 0) return _Final.none;
    return jong == 8 ? _Final.rieul : _Final.other;
  }

  final ch = String.fromCharCode(code);
  // 0 영 · 1 일 · 2 이 · 3 삼 · 4 사 · 5 오 · 6 육 · 7 칠 · 8 팔 · 9 구
  const digits = {
    '0': _Final.other,
    '1': _Final.rieul,
    '2': _Final.none,
    '3': _Final.other,
    '4': _Final.none,
    '5': _Final.none,
    '6': _Final.other,
    '7': _Final.rieul,
    '8': _Final.rieul,
    '9': _Final.none,
  };
  final digit = digits[ch];
  if (digit != null) return digit;

  if (RegExp(r'[A-Za-z]').hasMatch(ch)) {
    final tail = RegExp(r'[A-Za-z]+$').firstMatch(trimmed)!.group(0)!;
    // 대문자로만 된 약어는 끝 글자를 알파벳 이름으로 읽는다(PR → 피알, API → 에이피아이).
    if (tail == tail.toUpperCase()) {
      return switch (tail[tail.length - 1]) {
        'L' || 'R' => _Final.rieul,
        'M' || 'N' => _Final.other,
        _ => _Final.none,
      };
    }
    final lower = tail.toLowerCase();
    if (lower.endsWith('l')) return _Final.rieul;
    if (lower.endsWith('m') || lower.endsWith('n') || lower.endsWith('ng')) {
      return _Final.other;
    }
    return _Final.none;
  }
  return _Final.other;
}
