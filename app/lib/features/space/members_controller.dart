import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/invites_api.dart';
import '../../data/api/members_api.dart';
import '../../domain/models/space.dart';
import '../../domain/models/space_member.dart';
import '../auth/auth_controller.dart';
import 'space_controller.dart';

final membersApiProvider =
    Provider<MembersApi>((ref) => MembersApi(ref.watch(apiClientProvider)));

/// 현재 스페이스의 멤버 목록. **멘션 자동완성이 쓴다.**
///
/// 캐시하지 않는다. 멤버 목록은 대화를 읽는 데 필요한 값이 아니라 글을 **쓸 때만**
/// 필요하고, 오프라인에서는 어차피 전송도 못 한다. 카테고리와 달리 없다고 해서
/// 화면이 잘못 그려지지도 않는다(자동완성 후보가 비어 있을 뿐이다).
///
/// 실패해도 던지지 않는다 — 자동완성이 안 뜰 뿐 메시지 입력은 계속돼야 한다.
final spaceMembersProvider =
    FutureProvider<List<SpaceMemberProfile>>((ref) async {
  final spaceId = ref.watch(currentSpaceIdProvider);
  if (spaceId == null) return const [];

  // 아래 family 와 따로 부른다 — 이쪽은 실패를 삼키고(자동완성이 비어 있을 뿐이다)
  // 그쪽은 던진다(설정 창이 오류를 보인다). 소켓 `member:*` 는 둘을 함께 무효화한다.
  try {
    return await ref.watch(membersApiProvider).list(spaceId);
  } catch (_) {
    return const [];
  }
});

/// 스페이스 하나의 멤버 목록(16단계). **실패를 던진다** — 스페이스 설정 창의 멤버
/// 섹션이 오류를 보여야 한다. 셸 밖(설정 창)에서도 쓰므로 현재 스페이스가 아니라
/// id 를 받는다. 소켓 `member:*` 는 둘을 함께 무효화한다.
final spaceMembersOfProvider =
    FutureProvider.family<List<SpaceMemberProfile>, String>(
  (ref, spaceId) => ref.watch(membersApiProvider).list(spaceId),
);

final invitesApiProvider =
    Provider<InvitesApi>((ref) => InvitesApi(ref.watch(apiClientProvider)));

/// 그 멤버의 역할을 바꾸거나 내보낼 수 있는가(16단계 설계 D7). 서버의 `outranks` 와
/// 같다 — admin 이상이, 나보다 **낮은** 사람만, 자기 자신은 아니다.
bool canManageMember({
  required SpaceRole me,
  required SpaceRole target,
  required bool self,
}) =>
    !self && me.atLeast(SpaceRole.admin) && me.rank > target.rank;

/// 화면에 보이는 역할 이름.
String roleLabel(SpaceRole role) => switch (role) {
      SpaceRole.owner => '소유자',
      SpaceRole.admin => '관리자',
      SpaceRole.member => '멤버',
      SpaceRole.guest => '손님',
    };

/// `userId` → 부르는 이름. **메시지에 이름이 실려 오지 않는 자리**에서 쓴다.
///
/// 아직 보내지 못한 큐의 메시지에는 서버가 붙여 주는 멘션 목록이 없고, 인용
/// 요약에는 본문만 온다. 둘 다 이 표가 없으면 `@알 수 없음` 으로 보인다.
final memberNamesProvider = Provider<Map<String, String>>((ref) {
  final members = ref.watch(spaceMembersProvider).value ?? const [];
  return {for (final m in members) m.userId: m.displayName};
});
