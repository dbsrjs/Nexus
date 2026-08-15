import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'features/realtime/socket_controller.dart';

void main() {
  runApp(const ProviderScope(child: NexusApp()));
}

class NexusApp extends ConsumerWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 소켓 연결과 채널 목록 동기화를 앱 수명 내내 살려 둔다. 화면에서 watch 하면
    // 그 화면을 벗어날 때 연결이 끊긴다.
    ref.watch(realtimeChannelSyncProvider);

    return MaterialApp.router(
      title: 'Nexus',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      // 다크가 기본이다 (design-system/tokens.css 가 다크를 :root 에 둔다).
      themeMode: ThemeMode.dark,
      theme: buildNexusTheme(brightness: Brightness.light),
      darkTheme: buildNexusTheme(brightness: Brightness.dark),
    );
  }
}
