import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **15단계 — Flutter · 안드로이드 기본 UI 를 쓰지 않는다**(설계 D1 · D2).
///
/// `lib/` 에서 `material.dart` · `cupertino.dart` 를 import 하는 파일이 **하나도 없어야
/// 한다.** 이관 중에는 줄어들기만 하는 허용 목록이었고(45개에서 시작), 15-3 에서
/// 비었다 — **다시 채우지 않는다.** 필요한 위젯이 없으면 `lib/ui/` 에 만든다.
///
/// 규칙이 말로만 있으면 다음 화면에서 Material 이 다시 들어온다. 그래서 두 방향을
/// 다 막았다 — 목록 밖의 새 import, 그리고 이관이 끝났는데 목록에 남은 파일.
const _allowed = <String>{};

final _platformImport = RegExp(
  r'''^\s*import\s+['"]package:flutter/(material|cupertino)\.dart['"]''',
  multiLine: true,
);

Set<String> _importers() {
  final found = <String>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (_platformImport.hasMatch(entity.readAsStringSync())) {
      found.add(entity.path.replaceAll(r'\', '/'));
    }
  }
  return found;
}

void main() {
  final importers = _importers();

  test('★ 허용 목록 밖에서 Material · Cupertino 를 import 하지 않는다', () {
    final extra = importers.difference(_allowed).toList()..sort();
    expect(
      extra,
      isEmpty,
      reason:
          '새 Material · Cupertino import 가 생겼다 — lib/ui/ 의 컴포넌트를 쓸 것: $extra',
    );
  });

  test('★ 이관이 끝난 파일은 허용 목록에서 뺀다 - 목록은 줄어들기만 한다', () {
    final stale = _allowed.difference(importers).toList()..sort();
    expect(
      stale,
      isEmpty,
      reason: '더는 Material 을 import 하지 않는 파일이 허용 목록에 남아 있다 — 빼라: $stale',
    );
  });

  test('lib/ui/ 는 허용 목록에 들어갈 수 없다 - 자체 컴포넌트는 처음부터 widgets 층이다', () {
    expect(_allowed.where((p) => p.startsWith('lib/ui/')), isEmpty);
    expect(importers.where((p) => p.startsWith('lib/ui/')), isEmpty);
  });
}
