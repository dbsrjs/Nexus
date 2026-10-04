import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'space_controller.dart';

/// 스페이스에서 빠진 사건 하나. `seq` 가 있어 **같은 스페이스가 두 번 빠져도** 두 번째가
/// 알려진다(같은 값이면 Riverpod 이 알리지 않는다 — 16단계 리뷰).
typedef SpaceRemoval = ({String spaceId, int seq});

/// 마지막으로 빠진 스페이스(16단계 설계 D13). 셸이 지켜보다가 그 스페이스를 보고
/// 있었으면 `/spaces` 로 보내고 알린다 — 소켓 리스너는 화면(BuildContext)을 모른다.
///
/// 셸은 값을 비우지 않는다 — 그 값이 남아 있는 동안 셸의 「채널이 사라짐」 리스너가 같은
/// 사건에 토스트를 한 번 더 띄우지 않는다. 그 스페이스에 다시 들어가면 셸이 비운다.
class RemovedSpace extends Notifier<SpaceRemoval?> {
  @override
  SpaceRemoval? build() => null;

  void mark(String spaceId) => state = (spaceId: spaceId, seq: (state?.seq ?? 0) + 1);

  void clear() => state = null;
}

final removedSpaceProvider =
    NotifierProvider<RemovedSpace, SpaceRemoval?>(RemovedSpace.new);

/// 그 스페이스를 기기에서 잊는다 — 캐시 · 큐 지우기, 목록 갱신, 셸에 알림.
///
/// 소켓 `space:removed` 와 나가기 응답이 함께 부른다. 먼저 오는 쪽이 하고 둘째는
/// 지울 것이 없어 헛돈다(멱등).
Future<void> forgetSpace(Ref ref, String spaceId) async {
  // **지우기 전에 알린다.** 캐시를 먼저 지우면 셸의 채널 목록이 비어 「이 채널을 더는 볼 수
  // 없습니다」가 먼저 뜨고, 네트워크 왕복 뒤 「스페이스에서 나왔습니다」가 한 번 더 떴다(16단계 리뷰).
  final removed = ref.read(removedSpaceProvider.notifier);
  final db = ref.read(appDatabaseProvider);
  final repository = ref.read(workspaceRepositoryProvider);
  removed.mark(spaceId);
  await db.purgeSpace(spaceId);
  await repository.refreshSpaces();
}

/// 위젯(`WidgetRef`)에서 [forgetSpace] 를 부르는 문.
final forgetSpaceProvider = Provider<Future<void> Function(String spaceId)>(
  (ref) => (spaceId) => forgetSpace(ref, spaceId),
);
