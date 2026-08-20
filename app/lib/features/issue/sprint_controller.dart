import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/sprints_api.dart';
import '../../data/repositories/sprint_repository.dart';
import '../../domain/models/issue.dart';
import '../../domain/models/sprint.dart';
import '../auth/auth_controller.dart';
import '../space/space_controller.dart';
import 'board_controller.dart';

final sprintsApiProvider = Provider<SprintsApi>(
  (ref) => SprintsApi(ref.watch(apiClientProvider)),
);

final sprintRepositoryProvider = Provider<SprintRepository>(
  (ref) => SprintRepository(
    api: ref.watch(sprintsApiProvider),
    db: ref.watch(appDatabaseProvider),
  ),
);

/// 캐시를 구독한다. 오프라인에서도 필터가 살아 있어야 한다.
final sprintListProvider = StreamProvider<List<Sprint>>((ref) {
  final spaceId = ref.watch(currentSpaceIdProvider);
  if (spaceId == null) return Stream.value(const []);
  return ref.watch(sprintRepositoryProvider).watchSprints(spaceId);
});

/// 지금 도는 스프린트. 스페이스당 하나라 목록에서 골라내면 된다.
final activeSprintProvider = Provider<Sprint?>((ref) {
  final sprints = ref.watch(sprintListProvider).value ?? const <Sprint>[];
  for (final sprint in sprints) {
    if (sprint.state == SprintState.active) return sprint;
  }
  return null;
});

/// 보드가 무엇을 보여 줄지.
///
/// **백로그는 별도 목록이 아니라 필터다** — `sprintId` 가 비어 있는 이슈의
/// 집합이 곧 백로그이기 때문이다(설계 §3).
enum BoardScope {
  /// 스프린트에 있든 없든 전부.
  all,

  /// 지금 도는 스프린트의 것만.
  activeSprint,

  /// 어느 스프린트에도 없는 것만.
  backlog,
}

class BoardScopeNotifier extends Notifier<BoardScope> {
  @override
  BoardScope build() => BoardScope.all;

  void set(BoardScope scope) => state = scope;
}

final boardScopeProvider = NotifierProvider<BoardScopeNotifier, BoardScope>(
  BoardScopeNotifier.new,
);

/// 필터를 적용한 보드. 캐시를 다시 받지 않고 **화면에서 거른다** —
/// 이슈는 이미 전부 캐시에 있고, 서버를 한 번 더 부르면 오프라인에서 필터가
/// 동작하지 않는다.
final scopedBoardProvider = Provider<Map<IssueStatus, List<Issue>>>((ref) {
  final board = ref.watch(boardProvider);
  final scope = ref.watch(boardScopeProvider);
  if (scope == BoardScope.all) return board;

  final activeId = ref.watch(activeSprintProvider)?.id;

  bool keep(Issue issue) => switch (scope) {
    BoardScope.all => true,
    BoardScope.backlog => issue.sprintId == null,
    // 도는 스프린트가 없으면 걸러 낼 기준이 없다. 빈 보드를 보여 주는 것이
    // 맞다 — "지금 스프린트의 일"이 없다는 뜻이기 때문이다.
    BoardScope.activeSprint =>
      activeId != null && issue.sprintId == activeId,
  };

  return {
    for (final entry in board.entries)
      entry.key: entry.value.where(keep).toList(growable: false),
  };
});

String boardScopeLabel(BoardScope scope) => switch (scope) {
  BoardScope.all => '전체',
  BoardScope.activeSprint => '이번 스프린트',
  BoardScope.backlog => '백로그',
};

String sprintStateLabel(SprintState state) => switch (state) {
  SprintState.planned => '계획',
  SprintState.active => '진행 중',
  SprintState.closed => '완료',
};

/// 스프린트 화면이 부르는 동작들.
class SprintActions {
  SprintActions(this._ref);

  final Ref _ref;

  Future<bool> refresh() async {
    final spaceId = _ref.read(currentSpaceIdProvider);
    if (spaceId == null) return false;
    return _ref.read(sprintRepositoryProvider).refresh(spaceId);
  }

  Future<bool> create({
    required String name,
    String? goal,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final spaceId = _ref.read(currentSpaceIdProvider);
    if (spaceId == null) return false;
    final created = await _ref
        .read(sprintRepositoryProvider)
        .create(
          spaceId,
          name: name,
          goal: goal,
          startsAt: startsAt,
          endsAt: endsAt,
        );
    return created != null;
  }

  Future<bool> setState(String sprintId, SprintState state) async {
    final spaceId = _ref.read(currentSpaceIdProvider);
    if (spaceId == null) return false;
    final updated = await _ref
        .read(sprintRepositoryProvider)
        .setState(spaceId, sprintId, state);
    return updated != null;
  }

  Future<bool> remove(String sprintId) async {
    final spaceId = _ref.read(currentSpaceIdProvider);
    if (spaceId == null) return false;
    return _ref.read(sprintRepositoryProvider).remove(spaceId, sprintId);
  }
}

final sprintActionsProvider = Provider<SprintActions>(SprintActions.new);

/// 번다운은 캐시하지 않는다 — 열 때마다 받는다.
final burndownProvider = FutureProvider.autoDispose
    .family<Burndown?, String>((ref, sprintId) async {
      final spaceId = ref.watch(currentSpaceIdProvider);
      if (spaceId == null) return null;
      return ref.watch(sprintRepositoryProvider).burndown(spaceId, sprintId);
    });
