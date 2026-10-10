import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/channel.dart';
import '../../ui/ui.dart';
import '../channel/channel_controller.dart';
import '../channel/dm.dart';
import '../chat/chat_header.dart';
import '../chat/chat_screen.dart';
import '../space/space_controller.dart';
import 'voice_controller.dart';
import 'voice_session.dart';
import 'voice_widgets.dart';

/// 채널 주소(`c/:channelId`)의 본문 — 음성 채널이면 통화 화면, 아니면 대화(20단계).
///
/// 라우트를 따로 두지 않는 이유: 채널 주소 하나가 사이드바 선택 · 딥링크 · 알림 이동을 다 받는다.
/// 종류에 따라 주소가 갈리면 그 셋이 모두 종류를 알아야 한다.
class ChannelRouteBody extends ConsumerWidget {
  const ChannelRouteBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(
      currentChannelProvider.select((c) => c?.isVoice ?? false),
    );
    return voice ? const VoiceChannelScreen() : const ChatScreen();
  }
}

/// 음성 채널 화면 — 들어가기 전에는 누가 있는지와 「참여하기」, 들어간 뒤에는 사람들과 버튼.
class VoiceChannelScreen extends ConsumerWidget {
  const VoiceChannelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(currentChannelProvider);
    final call = ref.watch(voiceSessionProvider);
    if (channel == null) return const NxPage(body: SizedBox.shrink());
    final inThisCall = call?.channelId == channel.id;

    return NxPage(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VoiceChannelHeader(name: channel.name, topic: channel.topic),
          Expanded(
            child: inThisCall
                ? _InCall(call: call!)
                : _Lobby(channel: channel, otherCall: call),
          ),
        ],
      ),
    );
  }
}

/// 들어가기 전.
class _Lobby extends ConsumerStatefulWidget {
  const _Lobby({required this.channel, this.otherCall});

  final Channel channel;

  /// 다른 채널의 통화에 있으면 그것 — 들어가면 그쪽에서 나온다고 미리 말한다.
  final VoiceCall? otherCall;

  @override
  ConsumerState<_Lobby> createState() => _LobbyState();
}

class _LobbyState extends ConsumerState<_Lobby> {
  bool _joining = false;

  Future<void> _join() async {
    final spaceId = ref.read(currentSpaceIdProvider);
    if (spaceId == null || _joining) return;
    setState(() => _joining = true);
    await joinVoiceChannel(
      context,
      ref,
      spaceId: spaceId,
      channel: widget.channel,
    );
    if (mounted) setState(() => _joining = false);
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final enabled = ref.watch(voiceEnabledProvider).value;
    final userIds = ref.watch(voiceRosterOfProvider(widget.channel.id));
    final members = ref.watch(memberProfilesProvider);
    final notice = ref.watch(voiceEndedProvider);
    final endedText = notice?.channelId != widget.channel.id
        ? null
        : switch (notice!.reason) {
            VoiceEnd.removed => '통화에서 나가졌습니다. 이 채널을 볼 수 없게 됐을 수 있습니다.',
            VoiceEnd.lost => '연결이 끊겨 통화에서 나왔습니다.',
            VoiceEnd.left => null,
          };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(NxSpacing.sp8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (endedText != null) ...[
              Text(
                endedText,
                textAlign: TextAlign.center,
                style: nx.text.secondary.copyWith(color: c.warning),
              ),
              const SizedBox(height: NxSpacing.sp6),
            ],
            if (userIds.isEmpty)
              Text('아직 아무도 없습니다.', style: nx.text.secondary)
            else ...[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: NxSpacing.sp6,
                runSpacing: NxSpacing.sp6,
                children: [
                  for (final id in userIds)
                    _PersonTile(userId: id, name: members[id]?.displayName),
                ],
              ),
            ],
            const SizedBox(height: NxSpacing.sp8),
            if (enabled == false)
              Text(
                '이 서버에는 통화가 설정되지 않았습니다.',
                textAlign: TextAlign.center,
                style: nx.text.secondary,
              )
            else ...[
              NxButton(
                label: '참여하기',
                icon: NxIcons.speaker,
                size: NxSize.lg,
                loading: _joining,
                // 켜져 있는지 아직 모르면 누를 수 없게 둔다 — 누른 뒤에야 실패하는 버튼을 만들지 않는다.
                onPressed: enabled == true ? _join : null,
              ),
              if (widget.otherCall case final other?) ...[
                const SizedBox(height: NxSpacing.sp4),
                Text(
                  '지금 있는 「${other.channelName}」 통화에서 나옵니다.',
                  textAlign: TextAlign.center,
                  style: nx.text.meta,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// 들어간 뒤.
class _InCall extends ConsumerWidget {
  const _InCall({required this.call});

  final VoiceCall call;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final members = ref.watch(memberProfilesProvider);
    final session = ref.read(voiceSessionProvider.notifier);

    final notes = <Widget>[
      if (call.link == VoiceLink.connecting)
        Text('연결하는 중…', style: nx.text.secondary)
      else if (call.link == VoiceLink.reconnecting)
        Text('다시 연결하는 중…', style: nx.text.secondary.copyWith(color: c.warning)),
      if (!call.canSpeak) Text('읽기 전용 채널이라 듣기만 합니다.', style: nx.text.secondary),
      // 웹의 자동 재생 정책 — 사람이 한 번 눌러야 소리가 난다.
      if (call.audioBlocked)
        NxButton(
          label: '소리 켜기',
          kind: NxButtonKind.secondary,
          size: NxSize.sm,
          onPressed: session.startAudio,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NxSpacing.sp8),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: NxSpacing.sp6,
                runSpacing: NxSpacing.sp6,
                children: [
                  for (final p in call.peers)
                    _PersonTile(
                      userId: p.userId,
                      name: members[p.userId]?.displayName,
                      speaking: p.speaking,
                      micOff: !p.micOn,
                    ),
                ],
              ),
            ),
          ),
        ),
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: NxSpacing.sp4),
            child: Center(child: note),
          ),
        Container(
          padding: const EdgeInsets.all(NxSpacing.sp6),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.divider)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NxButton(
                label: call.micOn ? '마이크 끄기' : '마이크 켜기',
                icon: call.micOn ? NxIcons.mic : NxIcons.micOff,
                kind: NxButtonKind.secondary,
                onPressed: call.canSpeak || call.micOn
                    ? () => toggleVoiceMic(context, ref)
                    : null,
              ),
              const SizedBox(width: NxSpacing.sp5),
              NxButton(
                label: '나가기',
                icon: NxIcons.hangUp,
                kind: NxButtonKind.danger,
                onPressed: session.leave,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 사람 한 칸 — 큰 아바타 · 이름 · 마이크 꺼짐.
class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.userId,
    required this.name,
    this.speaking = false,
    this.micOff = false,
  });

  final String userId;
  final String? name;
  final bool speaking;
  final bool micOff;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final label = name ?? '알 수 없는 사람';
    return Semantics(
      label: [label, if (speaking) '말하는 중', if (micOff) '마이크 꺼짐'].join(', '),
      excludeSemantics: true,
      child: SizedBox(
        width: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VoiceAvatar(userId: userId, size: 56, speaking: speaking),
            const SizedBox(height: NxSpacing.sp3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (micOff) ...[
                  NxIcon(NxIcons.micOff, size: NxIconSize.sm, color: c.danger),
                  const SizedBox(width: NxSpacing.sp2),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: nx.text.sm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
