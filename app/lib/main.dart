import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
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

    // **Material 이 없는 뼈대**(15-3). 테마 · 토스트 · 스크롤은 NxRoot 가 깐다 — Material 의
    // 물결 · 오버스크롤 글로 · 페이지 전환 · 선택 손잡이가 새어 나올 틈이 없다.
    //
    // **기본은 시스템**이다. 디자인은 다크를 전제로 했지만(design-system/tokens.css 가
    // 다크를 :root 에 둔다) OS 설정을 따르는 것이 사용자가 이미 고른 취향을 존중하는
    // 길이다. 설정 창 「화면」 에서 바꿀 수 있다.
    return WidgetsApp.router(
      title: 'Nexus',
      // 작업 전환기 · 웹 탭의 색. 다크 액센트.
      color: const Color(0xFF77AECF),
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          NxRoot(preference: preference, child: child!),
    );
  }
}
