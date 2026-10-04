import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/space.dart';
import '../../ui/ui.dart';
import '../settings/settings_widgets.dart';
import '../space/space_controller.dart';

/// 스페이스 설정 「일반」(16단계 설계 D14) — 이름 바꾸기만. admin+ 에게만 보인다.
class GeneralSection extends ConsumerStatefulWidget {
  const GeneralSection({super.key, required this.space});

  final Space space;

  @override
  ConsumerState<GeneralSection> createState() => _GeneralSectionState();
}

class _GeneralSectionState extends ConsumerState<GeneralSection> {
  late final _name = TextEditingController(text: widget.space.name);
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(spacesApiProvider).rename(widget.space.id, _name.text.trim());
      // 레일 · 채널 판 머리 줄이 스페이스 목록(drift)을 본다.
      await ref.read(workspaceRepositoryProvider).refreshSpaces();
      if (mounted) {
        NxToast.show(context, '이름을 바꿨습니다', kind: NxToastKind.success);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = messageFor(e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = _name.text.trim();
    // 서버 DTO 와 같은 1~60자.
    final canSave = !_busy &&
        trimmed.isNotEmpty &&
        trimmed.length <= 60 &&
        trimmed != widget.space.name;

    return SettingsPage(
      title: '일반',
      children: [
        const SettingsLabel('스페이스 이름'),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: NxField(
            controller: _name,
            maxLength: 60,
            onSubmitted: (_) {
              if (canSave) _save();
            },
          ),
        ),
        if (_error != null) SettingsError(_error!),
        const SizedBox(height: NxSpacing.sp6),
        Align(
          alignment: Alignment.centerLeft,
          child: NxButton(
            label: '저장',
            loading: _busy,
            onPressed: canSave ? _save : null,
          ),
        ),
      ],
    );
  }
}
