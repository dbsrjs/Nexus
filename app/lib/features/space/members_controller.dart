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
