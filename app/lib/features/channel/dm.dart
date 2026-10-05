import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/channel.dart';
import '../../domain/models/space_member.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../ui/ui.dart';
import '../auth/auth_controller.dart';
import '../space/members_controller.dart';
import '../space/space_controller.dart';
import 'channel_controller.dart';

/// 현재 스페이스의 DM — 최근 메시지 순(17단계 D10).
///
/// **메시지가 없는 DM 은 숨긴다** — 열기만 하고 말을 안 한 DM 이 상대 목록에 빈 줄로 뜨지
/// 않게. 지금 열려 있는 것은 예외다(방금 연 DM 이 사라지면 안 된다). 서버는 숨기지 않는다.
final dmChannelsProvider = Provider<List<Channel>>((ref) {
  final channels = ref.watch(channelsProvider).value ?? const <Channel>[];
  final current = ref.watch(currentChannelIdProvider);
  final dms = channels
      .where((c) => c.isDm && (c.lastMessageAt != null || c.id == current))
      .toList();
  // 메시지가 없는(방금 연) DM 이 맨 위 — 그 사람과 지금 말을 시작하려는 참이다.
  final far = DateTime.utc(9999);
  dms.sort((a, b) => (b.lastMessageAt ?? far).compareTo(a.lastMessageAt ?? far));
  return dms;
});

/// `userId` → 현재 스페이스의 멤버. DM 줄 · 머리 줄이 이름과 사진을 찾는다(D9).
final memberProfilesProvider = Provider<Map<String, SpaceMemberProfile>>((ref) {
  final members = ref.watch(spaceMembersProvider).value ?? const <SpaceMemberProfile>[];
  return {for (final m in members) m.userId: m};
});

/// DM 상대를 부르는 이름. 멤버 목록에 없으면(떠났거나 아직 못 받았다) 「나간 사람」.
String dmPeerName(Map<String, SpaceMemberProfile> members, Channel channel) =>
    members[channel.dmUserId]?.displayName ?? '나간 사람';

/// 그 사람과의 DM 을 열고 들어간다(D3). 목록을 먼저 다시 받아 들어간 화면이 그 DM 을 안다.
Future<void> openDm(BuildContext context, WidgetRef ref, String userId) async {
  final spaceId = ref.read(currentSpaceIdProvider);
  if (spaceId == null) return;
  await openDmIn(context, ref, spaceId, userId);
}

/// 셸 밖(스페이스 설정 창)에서도 쓰므로 스페이스를 받는 갈래.
Future<void> openDmIn(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
  String userId,
) async {
  try {
    final dm = await ref.read(channelsApiProvider).openDm(spaceId, userId);
    await ref.read(workspaceRepositoryProvider).refreshChannels(spaceId);
    if (context.mounted) context.go('/s/$spaceId/c/${dm.id}');
  } on ApiException catch (e) {
    if (context.mounted) {
      NxToast.show(context, messageFor(e.failure), kind: NxToastKind.error);
    }
  }
}

/// 말을 걸 사람을 고른다(D11). 고르면 그 DM 으로 간다.
Future<void> showDmPicker(BuildContext context, WidgetRef ref, {VoidCallback? onOpened}) async {
  final picked = await NxDialog.panel<String>(
    context,
    title: '다이렉트 메시지',
    builder: (_) => const _DmPicker(),
  );
  if (picked == null || !context.mounted) return;
  await openDm(context, ref, picked);
  onOpened?.call();
}

class _DmPicker extends ConsumerStatefulWidget {
  const _DmPicker();

  @override
  ConsumerState<_DmPicker> createState() => _DmPickerState();
}

class _DmPickerState extends ConsumerState<_DmPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final myId = ref.watch(
      authControllerProvider.select((a) => a is AuthSignedIn ? a.user.id : null),
    );
    final all = ref.watch(spaceMembersProvider);
    final q = _query.trim().toLowerCase();
    final candidates = (all.value ?? const <SpaceMemberProfile>[])
        .where((m) => m.userId != myId)
        .where((m) => q.isEmpty || m.displayName.toLowerCase().contains(q))
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(NxSpacing.sp7, 0, NxSpacing.sp7, NxSpacing.sp7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NxField(
            dense: true,
            hint: '이름으로 찾기',
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: NxSpacing.sp5),
          if (!all.hasValue)
            const NxSkeleton(lines: 3, lineHeight: 40)
          else if (candidates.isEmpty)
            Text(
              q.isEmpty ? '이 스페이스에 다른 멤버가 없습니다.' : '찾는 사람이 없습니다.',
              style: nx.text.secondary,
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                // 다이얼로그 안 목록 — 안전 영역 여백을 가져오지 않는다(CLAUDE.md §2, 16-2).
                padding: EdgeInsets.zero,
                children: [
                  for (final m in candidates)
                    NxRow(
                      leading: DmAvatar(userId: m.userId, name: m.displayName, avatarUrl: m.avatarUrl, size: 28),
                      title: m.displayName,
                      subtitle: roleLabel(m.role),
                      onPressed: () => Navigator.of(context).pop(m.userId),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// DM 자리의 사람 아바타. 17-2 에서 프레즌스 점이 여기에 붙는다 — 사람을 가리키는 자리는
/// 이것 하나를 쓴다(D20).
class DmAvatar extends StatelessWidget {
  const DmAvatar({
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
  Widget build(BuildContext context) =>
      UserAvatar(userId: userId, name: name, avatarUrl: avatarUrl, size: size);
}
