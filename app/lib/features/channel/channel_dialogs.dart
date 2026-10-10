import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_failure.dart';
import '../../ui/ui.dart';
import '../channel_settings/channel_settings_controller.dart';
import '../space/space_controller.dart';
import '../voice/voice_controller.dart';

/// 채널 만들기(16단계 설계 D15, admin+). 누른 카테고리 머리의 묶음에 들어간다.
/// 만들면 목록을 다시 받고 그 채널로 들어간다 — 만든 사람은 그 채널의 멤버다.
Future<void> showCreateChannelDialog(
  BuildContext context,
  WidgetRef ref, {
  required String spaceId,
  String? categoryId,
  VoidCallback? onCreated,
}) => NxDialog.panel<void>(
  context,
  title: '채널 만들기',
  // 통화가 켜진 서버에서만 종류를 고르게 한다(20단계) — 꺼진 서버의 음성 채널은 들어갈 수 없다.
  builder: (_) => Consumer(
    builder: (_, ref, _) => _CreateChannelForm(
      voiceAvailable: ref.watch(voiceEnabledProvider).value ?? false,
      onSubmit: (name, topic, isPrivate, voice) async {
        final channel = await ref
            .read(channelsApiProvider)
            .create(
              spaceId,
              name: name,
              topic: topic,
              categoryId: categoryId,
              isPrivate: isPrivate,
              voice: voice,
            );
        await ref.read(workspaceRepositoryProvider).refreshChannels(spaceId);
        return channel.id;
      },
      onDone: (id) {
        if (context.mounted) context.go('/s/$spaceId/c/$id');
        // 밀려 나온 채널 패널에서 만들었으면 닫는다 — 채널을 고를 때와 같다.
        onCreated?.call();
      },
    ),
  ),
);

class _CreateChannelForm extends StatefulWidget {
  const _CreateChannelForm({
    required this.onSubmit,
    required this.onDone,
    this.voiceAvailable = false,
  });

  final Future<String> Function(
    String name,
    String? topic,
    bool isPrivate,
    bool voice,
  )
  onSubmit;

  /// 「음성」을 고를 수 있나. 거짓이면 종류 고르기를 감춘다 — 글 채널만 만든다.
  final bool voiceAvailable;
  final void Function(String id) onDone;

  @override
  State<_CreateChannelForm> createState() => _CreateChannelFormState();
}

class _CreateChannelFormState extends State<_CreateChannelForm> {
  final _name = TextEditingController();
  final _topic = TextEditingController();
  bool _private = false;
  bool _voice = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _topic.dispose();
    super.dispose();
  }

  String get _trimmed => _name.text.trim();

  Future<void> _submit() async {
    if (_trimmed.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final topic = _topic.text.trim();
      final id = await widget.onSubmit(
        _trimmed,
        topic.isEmpty ? null : topic,
        _private,
        // 고르기를 감춘 뒤에 남은 값으로 음성 채널이 만들어지지 않게.
        widget.voiceAvailable && _voice,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onDone(id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        // 이름에서 만든 key 가 겹치면 409 — 앱에서는 서버 오류로 접힌다. 이름을 바꾸면 된다.
        _error = e.failure == ApiFailure.server
            ? '채널을 만들지 못했습니다. 이름이 겹치면 다른 이름으로 해 보세요.'
            : messageFor(e.failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp7,
        0,
        NxSpacing.sp7,
        NxSpacing.sp7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.voiceAvailable) ...[
            NxSegmented<bool>(
              label: '채널 종류',
              segments: const [(false, '글'), (true, '음성')],
              value: _voice,
              onChanged: (v) => setState(() => _voice = v),
            ),
            const SizedBox(height: NxSpacing.sp6),
          ],
          NxField(
            controller: _name,
            label: '이름',
            maxLength: 40,
            autofocus: true,
            error: _error,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: NxSpacing.sp6),
          NxField(controller: _topic, label: '주제(선택)', maxLength: 200),
          const SizedBox(height: NxSpacing.sp6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('비공개 채널', style: nx.text.strong),
                    Text(
                      '명단의 사람만 봅니다. 나중에 채널 설정에서 들일 수 있습니다.',
                      style: nx.text.meta,
                    ),
                  ],
                ),
              ),
              NxSwitch(
                value: _private,
                label: '비공개 채널',
                onChanged: (v) => setState(() => _private = v),
              ),
            ],
          ),
          const SizedBox(height: NxSpacing.sp7),
          Align(
            alignment: Alignment.centerRight,
            child: NxButton(
              label: '만들기',
              loading: _busy,
              onPressed: _trimmed.isEmpty ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}
