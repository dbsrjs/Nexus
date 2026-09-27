import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/api/api_failure.dart';
import '../../domain/models/user.dart';
import '../../shared/widgets/user_avatar.dart';
import '../auth/auth_controller.dart';
import 'settings_controller.dart';
import 'settings_widgets.dart';

/// 내 계정 — 사진 · 표시 이름 · 이메일(읽기 전용). 14단계 설계 D4 · D5.
class AccountSection extends ConsumerStatefulWidget {
  const AccountSection({super.key});

  @override
  ConsumerState<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<AccountSection> {
  final _name = TextEditingController();
  bool _busy = false;
  SettingsNotice? _photoNotice;
  SettingsNotice? _nameNotice;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    if (auth is AuthSignedIn) _name.text = auth.user.name;
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<User> Function() call, {
    required void Function(SettingsNotice) notice,
    required String done,
    bool avatar = false,
  }) async {
    setState(() => _busy = true);
    try {
      final user = await call();
      await applyMe(ref, user);
      notice(SettingsNotice.ok(done));
    } on ApiException catch (e) {
      notice(SettingsNotice.error(settingsMessageFor(e.failure, avatar: avatar)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPhoto() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await _run(
      () => ref.read(settingsApiProvider).uploadAvatar(bytes: bytes, filename: file.name),
      notice: (n) => _photoNotice = n,
      done: '사진을 바꿨습니다',
      avatar: true,
    );
  }

  Future<void> _removePhoto() => _run(
        () => ref.read(settingsApiProvider).removeAvatar(),
        notice: (n) => _photoNotice = n,
        done: '사진을 지웠습니다',
        avatar: true,
      );

  Future<void> _saveName() => _run(
        () => ref.read(settingsApiProvider).updateName(_name.text.trim()),
        notice: (n) => _nameNotice = n,
        done: '이름을 바꿨습니다',
      );

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthSignedIn) return const SizedBox.shrink();
    final user = auth.user;
    final theme = Theme.of(context);

    final trimmed = _name.text.trim();
    final nameChanged = trimmed != user.name;
    final nameValid = trimmed.isNotEmpty && trimmed.length <= 50;

    return SettingsPage(
      title: '내 계정',
      children: [
        const SettingsLabel('프로필 사진'),
        Row(
          children: [
            UserAvatar(userId: user.id, name: user.name, avatarUrl: user.avatarUrl, size: 96),
            const SizedBox(width: NexusSpacing.sp7),
            Expanded(
              child: Wrap(
                spacing: NexusSpacing.sp4,
                runSpacing: NexusSpacing.sp4,
                children: [
                  FilledButton(
                    onPressed: _busy ? null : _pickPhoto,
                    child: const Text('사진 바꾸기'),
                  ),
                  if (user.avatarUrl != null)
                    OutlinedButton(
                      onPressed: _busy ? null : _removePhoto,
                      child: const Text('사진 지우기'),
                    ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: NexusSpacing.sp4),
          child: Text(
            'PNG · JPEG · WebP · GIF, 5MB 이하. 가운데를 정사각형으로 잘라 씁니다.',
            style: theme.textTheme.bodySmall,
          ),
        ),
        if (_photoNotice != null) SettingsNoticeText(_photoNotice!),
        const SizedBox(height: NexusSpacing.sp9),
        const SettingsLabel('표시 이름'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _name,
                maxLength: 50,
                onSubmitted: (_) =>
                    (!_busy && nameChanged && nameValid) ? _saveName() : null,
                decoration: const InputDecoration(hintText: '다른 사람에게 보이는 이름'),
              ),
            ),
            const SizedBox(width: NexusSpacing.sp5),
            Padding(
              padding: const EdgeInsets.only(top: NexusSpacing.sp2),
              child: FilledButton(
                onPressed: (!_busy && nameChanged && nameValid) ? _saveName : null,
                child: const Text('저장'),
              ),
            ),
          ],
        ),
        if (_nameNotice != null) SettingsNoticeText(_nameNotice!),
        const SizedBox(height: NexusSpacing.sp9),
        const SettingsLabel('이메일'),
        Text(user.email, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
