import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/user.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../ui/ui.dart';
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
  String? _photoError;
  String? _nameError;

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
    required void Function(String?) error,
    required String done,
    bool avatar = false,
  }) async {
    setState(() {
      _busy = true;
      error(null);
    });
    try {
      final user = await call();
      await applyMe(ref, user);
      if (mounted) NxToast.show(context, done, kind: NxToastKind.success);
    } on ApiException catch (e) {
      error(settingsMessageFor(e.failure, avatar: avatar));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPhoto() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await _run(
      () => ref
          .read(settingsApiProvider)
          .uploadAvatar(bytes: bytes, filename: file.name),
      error: (e) => _photoError = e,
      done: '사진을 바꿨습니다',
      avatar: true,
    );
  }

  Future<void> _removePhoto() => _run(
    () => ref.read(settingsApiProvider).removeAvatar(),
    error: (e) => _photoError = e,
    done: '사진을 지웠습니다',
    avatar: true,
  );

  Future<void> _saveName() => _run(
    () => ref.read(settingsApiProvider).updateName(_name.text.trim()),
    error: (e) => _nameError = e,
    done: '이름을 바꿨습니다',
  );

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthSignedIn) return const SizedBox.shrink();
    final user = auth.user;
    final nx = NxTheme.of(context);

    final trimmed = _name.text.trim();
    final nameChanged = trimmed != user.name;
    final nameValid = trimmed.isNotEmpty && trimmed.length <= 50;
    final canSave = !_busy && nameChanged && nameValid;

    return SettingsPage(
      title: '내 계정',
      children: [
        const SettingsLabel('프로필 사진'),
        Row(
          children: [
            UserAvatar(
              userId: user.id,
              name: user.name,
              avatarUrl: user.avatarUrl,
              size: 88,
            ),
            const SizedBox(width: NxSpacing.sp7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: NxSpacing.sp4,
                    runSpacing: NxSpacing.sp4,
                    children: [
                      NxButton(
                        label: '사진 바꾸기',
                        onPressed: _busy ? null : _pickPhoto,
                      ),
                      if (user.avatarUrl != null)
                        NxButton(
                          label: '지우기',
                          kind: NxButtonKind.secondary,
                          onPressed: _busy ? null : _removePhoto,
                        ),
                    ],
                  ),
                  const SizedBox(height: NxSpacing.inset),
                  Text(
                    'PNG · JPEG · WebP · GIF, 5MB 이하 · 가운데를 정사각형으로 잘라 씁니다',
                    style: nx.text.meta,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_photoError != null) SettingsError(_photoError!),
        const SettingsGap(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NxField(
                label: '표시 이름',
                controller: _name,
                maxLength: 50,
                helper: '다른 사람에게 보이는 이름',
                error: _nameError,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => canSave ? _saveName() : null,
              ),
            ),
            const SizedBox(width: NxSpacing.sp4),
            // 라벨 줄만큼 내려 입력 칸과 높이를 맞춘다.
            Padding(
              // 토큰 밖: NxField 의 라벨 줄 높이(글자 + 간격)만큼 — 라벨 높이가 바뀌면 같이 바꾼다.
              padding: const EdgeInsets.only(top: 22),
              child: NxButton(
                label: '저장',
                onPressed: canSave ? _saveName : null,
              ),
            ),
          ],
        ),
        const SettingsGap(),
        const SettingsLabel('이메일'),
        Text(user.email, style: nx.text.base),
      ],
    );
  }
}
