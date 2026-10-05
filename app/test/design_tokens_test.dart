import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **화면은 디자인 토큰만 쓴다**(디자인 시스템 §8).
///
/// 색 · 투명도 · 글자 크기 · 아이콘 크기 · 모서리 반경 · 여백은 `lib/ui/theme.dart` 의 토큰(`NxColors` ·
/// `NxBrand` · `NxAlpha` · `NxFontSize` · `NxIconSize` · `NxRadius` · `NxSpacing`)에서만 꺼낸다. 화면에 숫자를
/// 박으면 다크 · 라이트 한쪽이 깨지거나, 같은 역할의 값이 화면마다 1~2px 씩 갈라진다
/// — 2026-10-06 점검에서 머리 줄 제목 굵기가 600 과 700 으로, 패널 안 항목 반경이
/// 6 과 8 로 갈라져 있었다.
///
/// **토큰으로 표현할 수 없는 값**(축소 미리보기 · 테두리 두께 보정 같은 광학 보정)은
/// 같은 줄이나 바로 윗줄에 `// 토큰 밖:` 과 이유를 적는다. 예외가 말없이 늘지 않게
/// 하는 장치다 — 이유를 못 적겠으면 토큰을 쓸 자리다.
const _tokenFiles = {'lib/ui/theme.dart', 'lib/ui/gallery.dart'};

const _marker = '토큰 밖:';

final _rules = <String, RegExp>{
  '색 리터럴(Color(0x…))': RegExp(r'Color\(0x[0-9A-Fa-f]+\)'),
  '글자 크기 숫자(fontSize: N)': RegExp(r'fontSize:\s*\d'),
  '모서리 반경 숫자(circular(N))': RegExp(r'circular\(\s*\d'),
  '여백 숫자(EdgeInsets…(N))': RegExp(
    r'EdgeInsets\.\w+\([^()]*(?<![\w.])[1-9]\d*(?:\.\d+)?(?![\w.])',
  ),
  '간격 숫자(SizedBox(width|height: N))': RegExp(
    r'SizedBox\((?:width|height):\s*\d[\d.]*\)',
  ),
  '투명도 숫자(withValues(alpha: N))': RegExp(r'withValues\(alpha:\s*\.?\d'),
  '아이콘 크기 숫자(NxIcon · NxSpinner size: N)': RegExp(
    r'(?:NxIcon\([^()]*|NxSpinner\()size:\s*\d',
  ),
};

class _Hit {
  _Hit(this.rule, this.path, this.line, this.text);
  final String rule;
  final String path;
  final int line;
  final String text;
  @override
  String toString() => '$path:$line  [$rule]  ${text.trim()}';
}

List<_Hit> _scan() {
  final hits = <_Hit>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (_tokenFiles.contains(path) ||
        path.endsWith('.g.dart') ||
        path.endsWith('.freezed.dart')) {
      continue;
    }
    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final code = line.split('//').first;
      final excused =
          line.contains(_marker) || (i > 0 && lines[i - 1].contains(_marker));
      if (excused) continue;
      _rules.forEach((rule, re) {
        if (re.hasMatch(code)) hits.add(_Hit(rule, path, i + 1, line));
      });
    }
  }
  return hits;
}

void main() {
  test('★ 화면 코드에 색 · 글자 크기 · 반경 · 여백 숫자를 박지 않는다', () {
    final hits = _scan();
    expect(
      hits,
      isEmpty,
      reason:
          '토큰을 쓰거나, 토큰으로 못 쓰는 광학 보정이면 «// $_marker 이유» 를 적을 것:\n'
          '${hits.join('\n')}',
    );
  });

  test('검사가 실제로 잡는다 — 규칙마다 위반 한 줄을 넣어 본다', () {
    // 정규식이 아무것도 못 잡는 상태로 망가지면 위 테스트는 늘 통과한다.
    const samples = {
      '색 리터럴(Color(0x…))': 'color: const Color(0xFF123456),',
      '글자 크기 숫자(fontSize: N)': 'style: s.copyWith(fontSize: 15),',
      '모서리 반경 숫자(circular(N))': 'borderRadius: BorderRadius.circular(6),',
      '여백 숫자(EdgeInsets…(N))':
          'padding: const EdgeInsets.symmetric(horizontal: 10),',
      '간격 숫자(SizedBox(width|height: N))': 'const SizedBox(width: 6),',
      '투명도 숫자(withValues(alpha: N))': 'c.accent.withValues(alpha: .12)',
      '아이콘 크기 숫자(NxIcon · NxSpinner size: N)':
          'NxIcon(NxIcons.lock, size: 13, color: c.textSecondary)',
    };
    samples.forEach((rule, sample) {
      expect(_rules[rule]!.hasMatch(sample), isTrue, reason: rule);
    });
    // 토큰 · 0 은 통과해야 한다.
    expect(
      _rules['여백 숫자(EdgeInsets…(N))']!.hasMatch(
        'EdgeInsets.fromLTRB(NxSpacing.sp7, 0, NxSpacing.sp7, 0)',
      ),
      isFalse,
    );
  });
}
