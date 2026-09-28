import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'data/settings_storage.dart';
import 'features/realtime/socket_controller.dart';
import 'features/settings/theme_controller.dart';
import 'ui/root.dart';

Future<void> main() async {
  // 저장소를 읽으려면 바인딩이 서 있어야 한다.
  WidgetsFlutterBinding.ensureInitialized();

  // **테마를 runApp 앞에서 읽는다.** 뒤로 미루면 첫 프레임이 시스템 테마로
  // 그려졌다가 저장된 값으로 바뀌어 깜빡인다.
  final themeMode = await SettingsStorage().readThemePreference();

  runApp(
    ProviderScope(
      overrides: [initialThemeModeProvider.overrideWithValue(themeMode)],
      child: const NexusApp(),
    ),
  );
}

class NexusApp extends ConsumerWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 소켓 연결과 채널 목록 동기화를 앱 수명 내내 살려 둔다. 화면에서 watch 하면
    // 그 화면을 벗어날 때 연결이 끊긴다.
    ref.watch(realtimeChannelSyncProvider);

    final preference = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Nexus',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      // 자체 UI 의 바탕(15단계). 옮긴 화면은 NxTheme 을, 아직 안 옮긴 화면은 ThemeData 를
      // 본다 — 15-3 에서 MaterialApp 을 걷으면 이 줄만 남는다.
      //
      // **투명 Material 은 15-2 동안의 임시 발판이다.** 아직 안 옮긴 화면의 TextField ·
      // InkWell 은 Material 조상이 있어야 그려지는데, 옮긴 셸이 Scaffold 를 걷어 그 조상이
      // 사라졌다(대화 입력창이 「No Material widget found」로 멈췄다). 15-3 에서 지운다.
      builder: (context, child) => NxRoot(
        preference: preference,
        child: Material(type: MaterialType.transparency, child: child!),
      ),
      // **기본은 시스템**이다. 디자인은 다크를 전제로 했지만
      // (design-system/tokens.css 가 다크를 :root 에 둔다) OS 설정을 따르는
      // 것이 사용자가 이미 고른 취향을 존중하는 길이다. 레일 하단 계정
      // 메뉴에서 바꿀 수 있다.
      themeMode: switch (preference) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      theme: buildNexusTheme(brightness: Brightness.light),
      darkTheme: buildNexusTheme(brightness: Brightness.dark),
    );
  }
}
