import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme.dart';
import 'package:nexus_app/data/settings_storage.dart';
import 'package:nexus_app/ui/root.dart';

/// 옮긴 화면을 띄우는 테스트 호스트. **15-3 전까지는 실제 앱과 같은 짜임**(MaterialApp +
/// NxRoot)이라 화면 안에 아직 안 옮긴 위젯이 섞여 있어도 선다. 15-3 에서 이 안만
/// WidgetsApp 으로 바꾼다.
Widget nxTestApp({
  Widget? home,
  RouterConfig<Object>? router,
  Brightness brightness = Brightness.dark,
}) {
  assert((home == null) != (router == null), 'home 과 router 중 하나만');
  final preference = brightness == Brightness.dark
      ? ThemePreference.dark
      : ThemePreference.light;
  // main.dart 와 같은 임시 발판(15-3 에서 지운다).
  Widget root(BuildContext context, Widget? child) => NxRoot(
    preference: preference,
    child: Material(type: MaterialType.transparency, child: child!),
  );
  final theme = buildNexusTheme(brightness: brightness);
  return router != null
      ? MaterialApp.router(theme: theme, routerConfig: router, builder: root)
      : MaterialApp(theme: theme, home: home, builder: root);
}
