import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_widgets.dart';
import 'theme_controller.dart';

/// 화면 — 테마. 예전에는 계정 메뉴에 있었다. 같은 설정이 두 곳에 있으면 어느
/// 쪽이 진짜인지 묻게 되어 이곳 하나로 옮겼다(14단계 설계 D3).
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    Widget option(String label, String hint, ThemeMode mode) {
      final selected = current == mode;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          label,
          style: selected
              ? theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                )
              : theme.textTheme.bodyMedium,
        ),
        subtitle: Text(hint),
        trailing: selected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
        onTap: () => ref.read(themeModeProvider.notifier).set(mode),
      );
    }

    return SettingsPage(
      title: '화면',
      children: [
        const SettingsLabel('테마'),
        option('시스템 설정', '운영체제의 밝기 설정을 따릅니다', ThemeMode.system),
        option('라이트', '밝은 배경', ThemeMode.light),
        option('다크', '어두운 배경', ThemeMode.dark),
      ],
    );
  }
}
