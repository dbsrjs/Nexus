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
    return NxTheme(
      data: NxThemeData.of(brightness),
      child: NxToastHost(
        child: ScrollConfiguration(
          behavior: const NxScrollBehavior(),
          child: child,
        ),
      ),
    );
  }
}
