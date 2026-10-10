import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/channel.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../ui/ui.dart';
import '../channel/dm.dart';
import 'voice_controller.dart';
import 'voice_session.dart';

/// 들어가기 — 실패하면 문구를 띄운다. 서버 문구를 쓰지 않는다(CLAUDE.md §3 앱 규칙).
Future<void> joinVoiceChannel(
  BuildContext context,
  WidgetRef ref, {
  required String spaceId,
  required Channel channel,
}) async {
  String? message;
  var kind = NxToastKind.error;
  try {
    final outcome = await ref
        .read(voiceSessionProvider.notifier)
        .join(spaceId: spaceId, channel: channel);
    if (outcome == VoiceJoinOutcome.micUnavailable) {
      message = '마이크를 쓸 수 없어 듣기만 합니다. 마이크 권한을 확인해 주세요.';
      kind = NxToastKind.info;
    }
  } on ApiException catch (e) {
    message = e.failure == ApiFailure.notFound
        ? '이 채널을 볼 수 없습니다.'
        : messageFor(e.failure);
  } catch (_) {
    // 토큰은 받았는데 미디어 서버에 닿지 못했다 — 서버의 LIVEKIT_URL 이나 방화벽(UDP)이 원인이다.
    message = '통화 서버에 연결하지 못했습니다. 잠시 후 다시 시도해 주세요.';
  }
  if (message != null && context.mounted) {
    NxToast.show(context, message, kind: kind);
  }
}

/// 마이크를 켜고 끈다. 켜다가 실패하면(권한을 거부했다) 알린다 — 통화는 그대로 둔다.
Future<void> toggleVoiceMic(BuildContext context, WidgetRef ref) async {
  final call = ref.read(voiceSessionProvider);
  if (call == null) return;
  try {
    await ref.read(voiceSessionProvider.notifier).setMic(!call.micOn);
  } catch (_) {
    if (context.mounted) {
      NxToast.show(
        context,
        '마이크를 켜지 못했습니다. 마이크 권한을 확인해 주세요.',
        kind: NxToastKind.error,
      );
    }
  }
}

/// 통화 중인 사람의 아바타. 말하고 있으면 둘레가 초록으로 빛난다(디스코드와 같은 신호).
///
/// 테두리는 늘 같은 두께로 둔다 — 말할 때만 두르면 아바타가 들썩인다.
class VoiceAvatar extends ConsumerWidget {
  const VoiceAvatar({
    super.key,
    required this.userId,
    required this.size,
    this.speaking = false,
  });

  final String userId;
  final double size;
  final bool speaking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = NxTheme.of(context).colors;
    final profile = ref.watch(memberProfilesProvider)[userId];
    return AnimatedContainer(
      duration: NxMotion.micro,
      padding: const EdgeInsets.all(NxSpacing.sp1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: speaking ? c.success : NxColors.transparent,
          width: NxSpacing.sp1,
        ),
      ),
      child: UserAvatar(
        userId: userId,
        name: profile?.displayName ?? '?',
        avatarUrl: profile?.avatarUrl,
        size: size,
      ),
    );
  }
}

/// 사이드바의 음성 채널 줄 아래 — 지금 그 채널에 있는 사람(20단계). 들어가지 않아도 보인다.
///
/// 명단은 서버가 알려 준 것이고, 말하는 중 · 마이크는 **내가 같은 통화에 있을 때만** 안다 —
/// 그 값은 미디어 연결에서만 나온다.
class VoiceRosterList extends ConsumerWidget {
  const VoiceRosterList({super.key, required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final userIds = ref.watch(voiceRosterOfProvider(channelId));
    final call = ref.watch(voiceSessionProvider);
    final members = ref.watch(memberProfilesProvider);
    final live = call?.channelId == channelId
        ? {for (final p in call!.peers) p.userId: p}
        : const <String, VoicePeer>{};
    if (userIds.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(
        left: NxSpacing.sp9,
        bottom: NxSpacing.sp2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final id in userIds)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: NxSpacing.sp1),
              child: Row(
                children: [
                  VoiceAvatar(
                    userId: id,
                    size: 18,
                    speaking: live[id]?.speaking ?? false,
                  ),
                  const SizedBox(width: NxSpacing.sp4),
                  Expanded(
                    child: Text(
                      members[id]?.displayName ?? '알 수 없는 사람',
                      overflow: TextOverflow.ellipsis,
                      style: nx.text.sm.copyWith(color: c.textSecondary),
                    ),
                  ),
                  if (live[id]?.micOn == false)
                    NxIcon(
                      NxIcons.micOff,
                      size: NxIconSize.xs,
                      color: c.borderStrong,
                      semanticLabel: '마이크 꺼짐',
                    ),
                  const SizedBox(width: NxSpacing.sp4),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 채널 패널 맨 아래의 통화 줄(20단계) — 통화 중이면 어느 화면에 있든 보인다. 누르면 그 채널로,
/// 버튼 둘은 마이크와 나가기. 디스코드의 「음성 연결됨」 칸과 같은 자리다.
class VoiceCallBar extends ConsumerWidget {
  const VoiceCallBar({super.key, this.onNavigate});

  /// 밀려 나온 패널에서 눌렀으면 패널을 닫는다.
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(voiceSessionProvider);
    if (call == null) return const SizedBox.shrink();
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final session = ref.read(voiceSessionProvider.notifier);
    final (status, color) = switch (call.link) {
      VoiceLink.connecting => ('연결하는 중…', c.warning),
      VoiceLink.reconnecting => ('다시 연결하는 중…', c.warning),
      VoiceLink.connected => ('음성 연결됨', c.success),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NxSpacing.sp5,
        vertical: NxSpacing.sp4,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: NxPressable(
              semanticLabel: '${call.channelName} 통화로 가기',
              onPressed: () {
                context.go('/s/${call.spaceId}/c/${call.channelId}');
                onNavigate?.call();
              },
              builder: (context, s) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status,
                    style: nx.text.sm.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    call.channelName,
                    overflow: TextOverflow.ellipsis,
                    style: nx.text.meta.copyWith(
                      color: s.hovered ? c.textPrimary : c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          NxIconButton(
            icon: call.micOn ? NxIcons.mic : NxIcons.micOff,
            label: call.micOn ? '마이크 끄기' : '마이크 켜기',
            selected: !call.micOn,
            // 읽기 전용 채널에서는 켤 수 없다 — 누를 수 없는 버튼으로 둔다(§3-7).
            onPressed: call.canSpeak || call.micOn
                ? () => toggleVoiceMic(context, ref)
                : null,
          ),
          NxIconButton(
            icon: NxIcons.hangUp,
            label: '통화에서 나가기',
            color: c.danger,
            onPressed: session.leave,
          ),
        ],
      ),
    );
  }
}
