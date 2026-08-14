import 'package:flutter/widgets.dart';

/// 화면 폭 분기. 값은 [앱 설계 §4](../../../docs/앱-설계.md)에서 가져왔다.
///
/// **분기는 셸(shell) 한 곳에서만 한다.** 화면 위젯은 셋이 공유하고, 어떤 폭인지
/// 알 필요가 없다. 이 규칙이 깨지면 화면마다 반응형 분기가 흩어져 손댈 수 없게 된다.
enum Layout {
  /// < 600 — 하단 탭, 채널 목록은 드로어
  mobile,

  /// 600 ~ 1023 — 스페이스 레일 + 채널 목록을 접이식 드로어로 합친다
  tablet,

  /// >= 1024 — 3단 고정
  desktop;

  static const double tabletMin = 600;
  static const double desktopMin = 1024;

  static Layout of(double width) {
    if (width >= desktopMin) return Layout.desktop;
    if (width >= tabletMin) return Layout.tablet;
    return Layout.mobile;
  }

  static Layout ofContext(BuildContext context) =>
      Layout.of(MediaQuery.sizeOf(context).width);

  bool get isMobile => this == Layout.mobile;
  bool get isDesktop => this == Layout.desktop;
}

/// 고정 폭. 앱 설계 §4 의 수치를 그대로 쓴다.
class NexusPaneWidth {
  const NexusPaneWidth._();

  /// 스페이스 레일
  static const double rail = 72;

  /// 카테고리 · 채널 목록
  static const double channels = 240;

  /// 스레드 · 이슈 · AI 패널 (토글) — 슬라이스 2 범위 밖
  static const double sidePanel = 320;
}
