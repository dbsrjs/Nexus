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
/// 걸린 범위의 바로 윗줄이나 그 안에 `// 토큰 밖:` 과 이유를 적는다. 예외가 말없이 늘지 않게
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

/// 주석을 같은 길이의 공백으로 지운다 — 위치를 그대로 두어야 걸린 줄을 짚을 수 있다.
String _stripComments(String source) => source.replaceAllMapped(
  RegExp(r'//[^\n]*'),
  (m) => ' ' * m.group(0)!.length,
);

int _lineOf(String text, int offset) =>
    '\n'.allMatches(text.substring(0, offset)).length;

/// **파일 전체에** 정규식을 맞춘다. 줄 단위로 보면 dart format 이 여러 줄로 쪼갠 호출
/// (`EdgeInsets.symmetric(` 다음 줄의 `vertical: 5,`) 안의 숫자를 놓친다 — 2026-10-06
/// 검토에서 실제로 그렇게 빠져나간 줄이 있었다.
List<_Hit> _scanSource(String path, String source) {
  final hits = <_Hit>[];
  final lines = source.split('\n');
  final code = _stripComments(source);
  _rules.forEach((rule, re) {
    for (final m in re.allMatches(code)) {
      final first = _lineOf(code, m.start);
      final last = _lineOf(code, m.end);
      // 걸린 범위의 바로 윗줄부터 끝 줄까지 어디에든 이유가 적혀 있으면 예외.
      final excused = [
        for (var i = first > 0 ? first - 1 : 0; i <= last; i++) lines[i],
      ].any((l) => l.contains(_marker));
      if (!excused) hits.add(_Hit(rule, path, last + 1, lines[last]));
    }
  });
  return hits;
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
    hits.addAll(_scanSource(path, entity.readAsStringSync()));
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

  test('★ 여러 줄로 쪼갠 호출 안의 숫자도 잡는다 — 줄 단위 검사가 놓쳤던 모양', () {
    expect(
      _scanSource(
        'x.dart',
        'padding: const EdgeInsets.symmetric(\n'
            '  horizontal: NxSpacing.sp4,\n'
            '  vertical: 5,\n'
            '),',
      ),
      hasLength(1),
    );
    expect(
      _scanSource('x.dart', 'NxIcon(\n  NxIcons.lock,\n  size: 13,\n)'),
      hasLength(1),
    );
  });

  test('윗줄 · 범위 안의 이유는 예외로 친다', () {
    expect(
      _scanSource(
        'x.dart',
        '// 토큰 밖: 광학 보정\npadding: const EdgeInsets.all(1.5),',
      ),
      isEmpty,
    );
    expect(
      _scanSource(
        'x.dart',
        'padding: const EdgeInsets.symmetric(\n'
            '  // 토큰 밖: 광학 보정\n'
            '  vertical: 5,\n'
            '),',
      ),
      isEmpty,
    );
    // 주석 안의 숫자는 코드가 아니다.
    expect(_scanSource('x.dart', '// fontSize: 15 는 옛 값'), isEmpty);
  });
}
