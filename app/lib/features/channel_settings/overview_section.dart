import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/channel.dart';
import '../../ui/ui.dart';
import '../settings/settings_widgets.dart';
import '../space/space_controller.dart';
import 'channel_settings_controller.dart';

/// 채널 설정 「개요」(16단계 D29 · D30) — 이름 · 주제 · 비공개. 고치는 것은 admin+,
/// 그 밖에는 읽기만 보인다.
class OverviewSection extends ConsumerStatefulWidget {
  const OverviewSection({
    super.key,
    required this.spaceId,
    required this.channel,
    required this.editable,
  });

  final String spaceId;
  final Channel channel;
  final bool editable;

  @override
  ConsumerState<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends ConsumerState<OverviewSection> {
  late final _name = TextEditingController(text: widget.channel.name);
  late final _topic = TextEditingController(text: widget.channel.topic ?? '');
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _topic.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _topic.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() call, String done) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await call();
      // 채널 목록(drift)이 이름 · 주제 · 비공개를 들고 있다. 서버도 rooms:invalidate 로 알린다.
      await ref.read(workspaceRepositoryProvider).refreshChannels(widget.spaceId);
      if (mounted) NxToast.show(context, done, kind: NxToastKind.success);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = messageFor(e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() => _run(
        () => ref.read(channelsApiProvider).update(
              widget.spaceId,
              widget.channel.id,
              name: _name.text.trim(),
              topic: _topic.text.trim(),
            ),
        '채널을 고쳤습니다',
      );

  Future<void> _setPrivate(bool private) async {
    if (private) {
      // 공개 채널의 멤버 행은 「읽어 본 사람」이라 명단과 다를 수 있다 — 숨기지 않고 알린다(D30).
      final ok = await NxDialog.confirm(
        context,
        title: '비공개 채널로 바꿀까요?',
        body: '지금까지 이 채널을 열어 본 사람이 명단이 됩니다. 나머지 사람에게는 채널이 사라지고, '
            '명단의 사람이 다시 들여야 볼 수 있습니다.',
        confirmLabel: '비공개로 바꾸기',
      );
      if (!ok || !mounted) return;
    }
    await _run(
      () => ref.read(channelsApiProvider).update(
            widget.spaceId,
            widget.channel.id,
            isPrivate: private,
          ),
      private ? '비공개 채널로 바꿨습니다' : '공개 채널로 바꿨습니다',
    );
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final channel = widget.channel;

    if (!widget.editable) {
      return SettingsPage(
        title: '개요',
        children: [
          const SettingsLabel('이름'),
          Text(channel.name, style: nx.text.body),
          const SizedBox(height: NxSpacing.sp7),
          const SettingsLabel('주제'),
          Text(
            (channel.topic?.isNotEmpty ?? false) ? channel.topic! : '주제가 없습니다.',
            style: nx.text.secondary,
          ),
          const SizedBox(height: NxSpacing.sp7),
          Text(
            channel.isPrivate ? '비공개 채널 — 명단의 사람만 봅니다.' : '공개 채널 — 스페이스 멤버 모두가 봅니다.',
            style: nx.text.meta,
          ),
        ],
      );
    }

    final name = _name.text.trim();
    final changed = name != channel.name || _topic.text.trim() != (channel.topic ?? '');
    final canSave = !_busy && changed && name.isNotEmpty && name.length <= 40;

    return SettingsPage(
      title: '개요',
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NxField(controller: _name, label: '이름', maxLength: 40),
              const SizedBox(height: NxSpacing.sp6),
              NxField(controller: _topic, label: '주제', maxLength: 200),
            ],
          ),
        ),
        if (_error != null) SettingsError(_error!),
        const SizedBox(height: NxSpacing.sp6),
        Align(
          alignment: Alignment.centerLeft,
          child: NxButton(label: '저장', loading: _busy, onPressed: canSave ? _save : null),
        ),
        const SettingsGap(),
        const SettingsLabel('비공개'),
        Row(
          children: [
            Expanded(
              child: Text(
                '켜면 명단의 사람만 이 채널을 봅니다. 관리자도 명단에 있어야 봅니다.',
                style: nx.text.secondary,
              ),
            ),
            const SizedBox(width: NxSpacing.sp6),
            NxSwitch(
              value: channel.isPrivate,
              label: '비공개 채널',
              onChanged: _busy ? null : _setPrivate,
            ),
          ],
        ),
      ],
    );
  }
}
