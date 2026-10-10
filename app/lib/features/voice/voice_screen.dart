import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/channel.dart';
import '../../ui/ui.dart';
import '../auth/auth_controller.dart';
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

/// 들어간 뒤. 누가 화면을 공유하면 그 화면을 크게, 사람은 아래 줄로 내린다(디스코드와 같다).
class _InCall extends ConsumerStatefulWidget {
  const _InCall({required this.call});

  final VoiceCall call;

  @override
  ConsumerState<_InCall> createState() => _InCallState();
}

class _InCallState extends ConsumerState<_InCall> {
  /// 사람이 고른 공유 화면. 그 사람이 공유를 멈추면 저절로 다른 화면으로 넘어간다.
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final members = ref.watch(memberProfilesProvider);
    final myId = ref.watch(
      authControllerProvider.select(
        (a) => a is AuthSignedIn ? a.user.id : null,
      ),
    );
    final shareMode = ref.watch(screenShareModeProvider);
    final session = ref.read(voiceSessionProvider.notifier);
    final focus = pickScreenFocus(
      call.screenSharers,
      picked: _picked,
      myId: myId,
    );
    String nameOf(String id) => members[id]?.displayName ?? '알 수 없는 사람';

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

    final people = [
      for (final p in call.peers)
        _PersonTile(
          userId: p.userId,
          name: members[p.userId]?.displayName,
          speaking: p.speaking,
          micOff: !p.micOn,
          sharing: call.screenSharers.contains(p.userId),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (focus == null)
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(NxSpacing.sp8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: NxSpacing.sp6,
                  runSpacing: NxSpacing.sp6,
                  children: people,
                ),
              ),
            ),
          )
        else ...[
          if (call.screenSharers.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NxSpacing.sp6,
                NxSpacing.sp5,
                NxSpacing.sp6,
                0,
              ),
              child: Wrap(
                spacing: NxSpacing.sp3,
                runSpacing: NxSpacing.sp3,
                children: [
                  for (final id in call.screenSharers)
                    NxChip(
                      label: id == myId ? '내 화면' : nameOf(id),
                      icon: NxIcons.screenShare,
                      selected: id == focus,
                      onPressed: () => setState(() => _picked = id),
                    ),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(NxSpacing.sp6),
              child: Semantics(
                label: focus == myId ? '내 화면' : '${nameOf(focus)}의 화면',
                image: true,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: c.bgBase,
                    borderRadius: BorderRadius.circular(NxRadius.lg),
                    border: Border.all(color: c.divider),
                  ),
                  child: session.screenView(focus),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              NxSpacing.sp6,
              0,
              NxSpacing.sp6,
              NxSpacing.sp5,
            ),
            child: Row(
              children: [
                for (final (i, tile) in people.indexed) ...[
                  if (i > 0) const SizedBox(width: NxSpacing.sp5),
                  tile,
                ],
              ],
            ),
          ),
        ],
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
          // 좁은 창에서 버튼 셋이 넘치지 않게 줄을 바꾼다.
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: NxSpacing.sp5,
            runSpacing: NxSpacing.sp4,
            children: [
              NxButton(
                label: call.micOn ? '마이크 끄기' : '마이크 켜기',
                icon: call.micOn ? NxIcons.mic : NxIcons.micOff,
                kind: NxButtonKind.secondary,
                onPressed: call.canSpeak || call.micOn
                    ? () => toggleVoiceMic(context, ref)
                    : null,
              ),
              // 보낼 수 없는 기기(Android · 휴대폰 브라우저)에는 버튼을 두지 않는다 — 눌러 봐야 실패한다(판단 #7).
              if (shareMode != ScreenShareMode.unsupported)
                NxButton(
                  label: call.screenShareOn ? '공유 중지' : '화면 공유',
                  icon: NxIcons.screenShare,
                  kind: NxButtonKind.secondary,
                  onPressed: call.canSpeak || call.screenShareOn
                      ? () => toggleScreenShare(context, ref)
                      : null,
                ),
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

/// 크게 볼 공유 화면. 사람이 고른 것이 아직 공유 중이면 그것, 아니면 **남의 화면** 먼저 —
/// 내 화면은 내가 이미 보고 있다. 아무도 공유하지 않으면 null.
@visibleForTesting
String? pickScreenFocus(List<String> sharers, {String? picked, String? myId}) {
  if (sharers.isEmpty) return null;
  if (picked != null && sharers.contains(picked)) return picked;
  for (final id in sharers) {
    if (id != myId) return id;
  }
  return sharers.first;
}

/// 사람 한 칸 — 큰 아바타 · 이름 · 마이크 꺼짐.
class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.userId,
    required this.name,
    this.speaking = false,
    this.micOff = false,
    this.sharing = false,
  });

  final String userId;
  final String? name;
  final bool speaking;
  final bool micOff;

  /// 화면을 공유 중이다.
  final bool sharing;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final label = name ?? '알 수 없는 사람';
    return Semantics(
      label: [
        label,
        if (speaking) '말하는 중',
        if (micOff) '마이크 꺼짐',
        if (sharing) '화면 공유 중',
      ].join(', '),
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
                if (sharing) ...[
                  NxIcon(
                    NxIcons.screenShare,
                    size: NxIconSize.sm,
                    color: c.accent,
                  ),
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
