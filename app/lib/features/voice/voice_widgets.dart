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

/// 화면 공유를 켜고 끈다(조각 2). 데스크톱은 앱이 고르기 창을 띄우고, 브라우저는 브라우저가 띄운다.
Future<void> toggleScreenShare(BuildContext context, WidgetRef ref) async {
  final call = ref.read(voiceSessionProvider);
  if (call == null) return;
  final session = ref.read(voiceSessionProvider.notifier);
  if (call.screenShareOn) {
    // 끄기의 실패는 사람이 할 일이 없다 — 나가면 미디어 서버가 트랙을 정리한다.
    try {
      await session.setScreenShare(false);
    } catch (_) {}
    return;
  }

  String? sourceId;
  if (ref.read(screenShareModeProvider) == ScreenShareMode.pickSource) {
    sourceId = await showScreenSourcePicker(context, ref);
    if (sourceId == null) return; // 고르지 않고 닫았다
  }
  try {
    await session.setScreenShare(true, sourceId: sourceId);
  } catch (e) {
    // 브라우저 고르기 창에서 「취소」를 누르면 getDisplayMedia 가 NotAllowedError 로 던진다 —
    // 사람이 고른 것이니 알리지 않는다. 그 밖(OS 의 화면 녹화 권한 · 장치)은 알린다.
    if (isScreenShareCancel(e) || !context.mounted) return;
    NxToast.show(
      context,
      '화면 공유를 시작하지 못했습니다. 화면 녹화 권한을 확인해 주세요.',
      kind: NxToastKind.error,
    );
  }
}

/// 브라우저 고르기 창의 취소인가. 웹의 DOMException 이 Dart 쪽으로 문자열로만 넘어와 이름으로 가른다.
@visibleForTesting
bool isScreenShareCancel(Object error) {
  final text = error.toString();
  return text.contains('NotAllowedError') || text.contains('AbortError');
}

/// 공유할 화면 · 창을 고른다(데스크톱). 고른 것의 id, 닫으면 null.
Future<String?> showScreenSourcePicker(BuildContext context, WidgetRef ref) =>
    NxDialog.panel<String>(
      context,
      title: '공유할 화면',
      width: 720,
      builder: (_) =>
          _ScreenSourcePicker(load: ref.read(screenSourcesProvider)),
    );

class _ScreenSourcePicker extends StatefulWidget {
  const _ScreenSourcePicker({required this.load});

  final Future<List<ScreenSource>> Function() load;

  @override
  State<_ScreenSourcePicker> createState() => _ScreenSourcePickerState();
}

class _ScreenSourcePickerState extends State<_ScreenSourcePicker> {
  // build 마다 다시 부르지 않게 한 번만 받는다 — 목록을 받는 데 미리보기 캡처가 든다.
  late final Future<List<ScreenSource>> _sources = widget.load();

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
      child: FutureBuilder<List<ScreenSource>>(
        future: _sources,
        builder: (context, snap) {
          if (snap.hasError) {
            return Text(
              '화면 목록을 받지 못했습니다. 화면 녹화 권한을 확인해 주세요.',
              style: nx.text.secondary,
            );
          }
          final sources = snap.data;
          if (sources == null) {
            return const NxSkeleton(lines: 2, lineHeight: 120);
          }
          if (sources.isEmpty) {
            return Text('공유할 화면이 없습니다.', style: nx.text.secondary);
          }
          return SingleChildScrollView(
            child: Wrap(
              spacing: NxSpacing.sp5,
              runSpacing: NxSpacing.sp5,
              children: [
                for (final s in sources)
                  _SourceTile(
                    source: s,
                    onPressed: () => Navigator.of(context).pop(s.id),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.source, required this.onPressed});

  final ScreenSource source;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final thumb = source.thumbnail;
    return NxPressable(
      onPressed: onPressed,
      semanticLabel: source.isScreen ? '화면 ${source.name}' : '창 ${source.name}',
      excludeChildSemantics: true,
      builder: (context, s) => SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: c.bgBase,
                  borderRadius: BorderRadius.circular(NxRadius.md),
                  border: Border.all(color: s.hovered ? c.accent : c.divider),
                ),
                child: thumb == null || thumb.isEmpty
                    ? Center(
                        child: NxIcon(
                          NxIcons.screenShare,
                          color: c.textSecondary,
                        ),
                      )
                    : Image.memory(thumb, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: NxSpacing.sp2),
            Text(
              source.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: nx.text.sm,
            ),
          ],
        ),
      ),
    );
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
