import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'data/settings_storage.dart';
import 'features/presence/presence_controller.dart';
import 'features/presence/typing_controller.dart';
import 'features/realtime/socket_controller.dart';
import 'features/space/members_controller.dart';
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

    // 멤버 이름표를 **앱이 사는 동안 내내** 구독해 둔다(listen — 앱을 다시 그리지 않는다).
    // 메시지 본문들이 build 중에 이것을 구독하는데, 구독자가 0 이 된 사이(셸 밖 설정 창에
    // 들어가 있는 동안) 멤버 목록이 바뀌면 Riverpod 3 이 멈춰 둔 갱신을 돌아온 본문의
    // build 안에서 터뜨려 「build 중 setState」로 멈췄다 — 15단계까지 간헐적으로 숨어
    // 있던 결함이다(16단계 app:flow 에서 잡았다). 셸은 설정 창이 열리면 내려가므로
    // 셸이 아니라 여기서 붙든다.
    ref.listen(memberNamesProvider, (_, _) {});

    // 프레즌스 · 입력 중(17단계)도 같은 이유로 뿌리에서 붙든다 — 채널을 열기 전에 온 이벤트를
    // 놓치지 않고, 이 기기의 상태(자리비움)를 앱이 사는 동안 내내 알린다.
    ref.listen(presenceProvider, (_, _) {});
    ref.listen(typingProvider, (_, _) {});
    ref.listen(presenceReporterProvider, (_, _) {});

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
