import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 로고 에셋이 **선언된 대로 실제로 있는지** 본다.
///
/// 잡으려는 실패는 하나다 — `design-system/logo/build_logo.py` 의 출력 이름을
/// 바꾸고 위젯 쪽을 안 고치는 것. 그러면 `analyze` 도 단위 테스트도 통과하고,
/// **앱을 띄워 로그인 화면을 열어야만** 회색 상자가 보인다. 에셋 로드는
/// 비동기라 위젯 테스트도 조용히 넘어간다.
void main() {
  test('위젯이 가리키는 로고 파일이 실제로 있다', () {
    final source = File('lib/shared/widgets/nexus_logo.dart').readAsStringSync();
    final referenced = RegExp(r"'(assets/logo/[^']+)'")
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toSet();

    expect(referenced, isNotEmpty, reason: '위젯이 로고를 하나도 안 쓴다');

    for (final path in referenced) {
      expect(File(path).existsSync(), isTrue,
          reason: '$path 가 없다. build_logo.py 를 다시 돌렸는지 확인할 것');
    }
  });

  test('pubspec 이 로고 디렉터리를 싣는다', () {
    // 선언이 빠지면 파일이 있어도 번들에 안 들어간다.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/logo/'));
  });
}
