import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'space_controller.dart';

/// 마지막으로 빠진 스페이스(16단계 설계 D13). 셸이 지켜보다가 그 스페이스를 보고
/// 있었으면 `/spaces` 로 보내고 알린다 — 소켓 리스너는 화면(BuildContext)을 모른다.
class RemovedSpace extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final removedSpaceProvider =
    NotifierProvider<RemovedSpace, String?>(RemovedSpace.new);

/// 그 스페이스를 기기에서 잊는다 — 캐시 · 큐 지우기, 목록 갱신, 셸에 알림.
///
/// 소켓 `space:removed` 와 나가기 응답이 함께 부른다. 먼저 오는 쪽이 하고 둘째는
/// 지울 것이 없어 헛돈다(멱등).
Future<void> forgetSpace(Ref ref, String spaceId) async {
  await ref.read(appDatabaseProvider).purgeSpace(spaceId);
  await ref.read(workspaceRepositoryProvider).refreshSpaces();
  ref.read(removedSpaceProvider.notifier).set(spaceId);
}

/// 위젯(`WidgetRef`)에서 [forgetSpace] 를 부르는 문.
final forgetSpaceProvider = Provider<Future<void> Function(String spaceId)>(
  (ref) => (spaceId) => forgetSpace(ref, spaceId),
);
