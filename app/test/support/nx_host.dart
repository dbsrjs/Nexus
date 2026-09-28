import 'package:flutter/widgets.dart';
import 'package:nexus_app/data/settings_storage.dart';
import 'package:nexus_app/ui/root.dart';

/// 화면을 띄우는 테스트 호스트 — **실제 앱과 같은 짜임**(WidgetsApp + NxRoot, 15-3).
/// Material 이 없으니 화면 안에 Material 위젯이 되살아나면 여기서 바로 깨진다.
Widget nxTestApp({
  Widget? home,
  RouterConfig<Object>? router,
  Brightness brightness = Brightness.dark,
}) {
  assert((home == null) != (router == null), 'home 과 router 중 하나만');
  final preference = brightness == Brightness.dark
      ? ThemePreference.dark
      : ThemePreference.light;
  Widget root(BuildContext context, Widget? child) =>
      NxRoot(preference: preference, child: child!);
  const color = Color(0xFF77AECF);
  return router != null
      ? WidgetsApp.router(color: color, routerConfig: router, builder: root)
      : WidgetsApp(
          color: color,
          builder: root,
          home: home,
          pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
              PageRouteBuilder<T>(
                settings: settings,
                pageBuilder: (context, _, _) => builder(context),
              ),
        );
}
