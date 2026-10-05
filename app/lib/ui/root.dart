import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data/settings_storage.dart';
import 'layout.dart';
import 'theme.dart';
import 'toast.dart';

/// 고른 테마 설정과 OS 밝기로 실제 밝기를 정한다.
Brightness resolveBrightness(ThemePreference preference, Brightness platform) =>
    switch (preference) {
      ThemePreference.system => platform,
      ThemePreference.light => Brightness.light,
      ThemePreference.dark => Brightness.dark,
    };

/// 앱 뿌리에 까는 자체 UI 의 바탕 — 테마 · 토스트 · 스크롤 동작.
///
/// 15-3 전까지는 `MaterialApp.router` 의 `builder` 에 끼워 **옮긴 화면과 안 옮긴 화면이
/// 한 앱에 함께 선다.** 15-3 에서 `WidgetsApp.router` 의 `builder` 로 자리만 옮긴다.
class NxRoot extends StatelessWidget {
  const NxRoot({super.key, required this.preference, required this.child});

  final ThemePreference preference;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = resolveBrightness(
      preference,
      MediaQuery.platformBrightnessOf(context),
    );
    final dark = brightness == Brightness.dark;
    // 시스템 바의 아이콘 밝기 — Material 의 AppBar 가 대신 해 주던 일이다. 없으면 라이트
    // 테마에서 상태 표시줄 아이콘이 흰색으로 남아 보이지 않았다(Android 에뮬레이터에서 발견).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: NxColors.transparent,
            systemNavigationBarColor: NxThemeData.of(brightness).colors.bgBase,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
          ),
      child: NxTheme(
        data: NxThemeData.of(brightness),
        child: NxToastHost(
          child: ScrollConfiguration(
            behavior: const NxScrollBehavior(),
            child: child,
          ),
        ),
      ),
    );
  }
}
