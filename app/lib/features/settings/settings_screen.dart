import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../shell/app_shell.dart';
import 'account_section.dart';
import 'appearance_section.dart';
import 'notifications_section.dart';
import 'password_section.dart';
import 'settings_controller.dart';

/// 설정 창(14단계). 셸 밖에 덮어서 연다 — 머무는 곳이 아니라 들어갔다 나오는 곳이다.
///
/// 폭 분기(두 단 · 한 단)는 `SettingsFrame`(app_shell.dart) 이 한다. 여기는 무엇을
/// 그릴지만 안다.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.section, this.spaceId, this.from});

  /// null 이면 목록 — 모바일에서 들어온 첫 화면이다. 넓은 화면은 「내 계정」을 연다.
  final SettingsSection? section;
  final String? spaceId;

  /// 들어오기 전 주소. 닫으면 여기로 돌아간다.
  final String? from;

  void _close(BuildContext context) => context.go(from ?? '/spaces');

  void _open(BuildContext context, SettingsSection target) =>
      context.go(settingsLocation(target, spaceId: spaceId, from: from));

  Widget _content(SettingsSection section) => switch (section) {
        SettingsSection.account => const AccountSection(),
        SettingsSection.password => const PasswordSection(),
        SettingsSection.notifications => NotificationsSection(initialSpaceId: spaceId),
        SettingsSection.appearance => const AppearanceSection(),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = section;
    return CallbackShortcuts(
      // 디스코드처럼 Esc 로 나간다.
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => _close(context)},
      child: Focus(
        autofocus: true,
        child: SettingsFrame(
          nav: _SettingsNav(
            selected: current,
            onSelect: (target) => _open(context, target),
            onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          title: current?.label ?? '설정',
          content: current == null ? null : _content(current),
          fallback: _content(SettingsSection.account),
          onClose: () => _close(context),
          onBack: () => context.go(settingsLocation(null, spaceId: spaceId, from: from)),
        ),
      ),
    );
  }
}

class _SettingsNav extends StatelessWidget {
  const _SettingsNav({
    required this.selected,
    required this.onSelect,
    required this.onSignOut,
  });

  final SettingsSection? selected;
  final ValueChanged<SettingsSection> onSelect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text('사용자 설정', style: theme.textTheme.labelSmall),
        ),
        for (final section in SettingsSection.values)
          ListTile(
            dense: true,
            leading: Icon(section.icon, size: 18),
            title: Text(section.label),
            selected: section == selected,
            onTap: () => onSelect(section),
          ),
        const Divider(),
        ListTile(
          dense: true,
          leading: Icon(Icons.logout, size: 18, color: theme.colorScheme.error),
          title: Text('로그아웃', style: TextStyle(color: theme.colorScheme.error)),
          onTap: onSignOut,
        ),
      ],
    );
  }
}
