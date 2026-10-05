import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/user_avatar.dart';
import '../../ui/ui.dart';
import '../space/members_controller.dart';
import 'presence_controller.dart';
import 'typing_controller.dart';

/// 프레즌스 점(17단계 D20) — 온라인은 채운 초록, 자리비움은 노랑, 오프라인은 속이 빈 회색.
/// 색만으로 가르지 않게 오프라인은 모양(빈 원)이 다르다.
class PresenceDot extends StatelessWidget {
  const PresenceDot({super.key, required this.presence, this.size = 8});

  final Presence presence;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    final (fill, ring) = switch (presence) {
      Presence.online => (c.success, c.success),
      Presence.away => (c.warning, c.warning),
      Presence.offline => (c.bgSurface, c.borderStrong),
    };
    return Semantics(
      label: switch (presence) {
        Presence.online => '온라인',
        Presence.away => '자리비움',
        Presence.offline => '오프라인',
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: ring, width: 1.5),
        ),
      ),
    );
  }
}

/// 상태 점을 단 사람 아바타. **「이 사람에게 지금 말을 걸까」를 정하는 자리**에만 쓴다 —
/// DM 줄 · DM 머리 줄 · 멤버 목록 · 사람 고르기 창(D20). 메시지 작성자에게는 달지 않는다.
class PresenceAvatar extends ConsumerWidget {
  const PresenceAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.size = 20,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presence = ref.watch(presenceOfProvider(userId));
    final dot = (size * 0.42).clamp(7.0, 12.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          UserAvatar(
            userId: userId,
            name: name,
            avatarUrl: avatarUrl,
            size: size,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            // 바탕색 테두리로 아바타에서 떼어 낸다.
            child: Container(
              // 토큰 밖: 상태 점을 아바타에서 떼는 테두리 두께(광학 보정).
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: NxTheme.of(context).colors.bgSurface,
                shape: BoxShape.circle,
              ),
              child: PresenceDot(presence: presence, size: dot),
            ),
          ),
        ],
      ),
    );
  }
}

/// 입력창 바로 위 「입력 중」 한 줄(D24). **비어 있어도 높이를 지킨다** — 메시지가 들썩이지 않게.
class TypingLine extends ConsumerWidget {
  const TypingLine({super.key, required this.channelId, this.parentId});

  final String channelId;
  final String? parentId;

  static const double height = 18;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final ids = ref.watch(typingUsersProvider(typingKey(channelId, parentId)));
    final names = ref.watch(memberNamesProvider);
    final label = typingLabel([for (final id in ids) names[id] ?? '누군가']);
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: NxSpacing.sp7),
        child: label == null
            ? null
            : Semantics(
                liveRegion: true,
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: nx.text.meta.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
      ),
    );
  }
}
