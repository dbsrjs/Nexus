import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

void main() {
  runApp(const ProviderScope(child: NexusApp()));
}

class NexusApp extends ConsumerWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
