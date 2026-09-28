import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **15단계 — Flutter · 안드로이드 기본 UI 를 쓰지 않는다**(설계 D1 · D2).
///
/// `lib/` 에서 `material.dart` · `cupertino.dart` 를 import 하는 파일은 아래
/// 허용 목록뿐이어야 한다. 이 목록은 **줄어들기만 한다** — 화면을 자체 UI 로
/// 옮기면 그 파일을 여기서 뺀다. 15-3 에서 목록이 비면 예외가 없어진다.
///
/// 규칙이 말로만 있으면 다음 화면에서 Material 이 다시 들어온다. 그래서
/// 두 방향을 다 막는다 — 목록 밖의 새 import, 그리고 이관이 끝났는데 목록에
/// 남은 파일(남겨 두면 그 파일에 Material 이 되돌아와도 모른다).
const _allowed = <String>{
  'lib/core/router.dart',
  'lib/core/theme.dart',
  'lib/features/ai/ai_panel.dart',
  'lib/features/chat/attachment_widgets.dart',
  'lib/features/chat/chat_screen.dart',
  'lib/features/chat/mention_composer_controller.dart',
  'lib/features/chat/selection_app_bar.dart',
  'lib/features/chat/thread_screen.dart',
  'lib/main.dart',
};

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
