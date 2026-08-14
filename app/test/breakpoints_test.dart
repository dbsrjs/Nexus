import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/core/breakpoints.dart';

/// 반응형 분기는 슬라이스 2 가 새로 들인 규칙이고, **경계값이 틀려도 화면은
/// 그럴듯하게 보인다** — 눈으로는 잘 안 잡힌다. 순수 함수라 테스트가 싸므로
/// 경계만 못 박아 둔다. (docs/앱-설계.md §4 의 600 · 1024)
void main() {
  test('경계값 — 600 미만은 mobile, 600 이상은 tablet', () {
    expect(Layout.of(599), Layout.mobile);
    expect(Layout.of(600), Layout.tablet);
  });

  test('경계값 — 1024 미만은 tablet, 1024 이상은 desktop', () {
    expect(Layout.of(1023), Layout.tablet);
    expect(Layout.of(1024), Layout.desktop);
  });

  test('실제 기기 폭', () {
    expect(Layout.of(360), Layout.mobile); // 흔한 안드로이드 폰
    expect(Layout.of(768), Layout.tablet); // iPad 세로
    expect(Layout.of(1440), Layout.desktop); // 데스크톱 창
  });

  test('0 이나 음수에서도 분기가 깨지지 않는다', () {
    // 창 크기가 0 으로 보고되는 순간이 있다(초기 프레임 · 최소화).
    expect(Layout.of(0), Layout.mobile);
    expect(Layout.of(-1), Layout.mobile);
  });
}
