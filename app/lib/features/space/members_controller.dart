import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/members_api.dart';
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

  try {
    return await ref.watch(membersApiProvider).list(spaceId);
  } catch (_) {
    return const [];
  }
});

/// `userId` → 부르는 이름. **메시지에 이름이 실려 오지 않는 자리**에서 쓴다.
///
/// 아직 보내지 못한 큐의 메시지에는 서버가 붙여 주는 멘션 목록이 없고, 인용
/// 요약에는 본문만 온다. 둘 다 이 표가 없으면 `@알 수 없음` 으로 보인다.
final memberNamesProvider = Provider<Map<String, String>>((ref) {
  final members = ref.watch(spaceMembersProvider).value ?? const [];
  return {for (final m in members) m.userId: m.displayName};
});
