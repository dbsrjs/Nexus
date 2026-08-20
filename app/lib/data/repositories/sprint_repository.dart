import '../../domain/models/sprint.dart';
import '../api/api_failure.dart';
import '../api/sprints_api.dart';
import '../local/app_database.dart';

/// 스프린트 캐시. 보드 필터가 쓰는 값이라 **오프라인에서도 보여야 한다**.
///
/// 번다운은 캐시하지 않는다 — 댓글과 같은 판단으로, 열 때마다 받는다.
class SprintRepository {
  SprintRepository({required SprintsApi api, required AppDatabase db})
    : _api = api,
      _db = db;

  final SprintsApi _api;
  final AppDatabase _db;

  Stream<List<Sprint>> watchSprints(String spaceId) => _db
      .watchSprints(spaceId)
      .map((rows) => rows.map(_toSprint).toList(growable: false));

  /// 실패를 던지지 않고 `false` 를 돌려준다. 오프라인은 오류가 아니다 —
  /// **캐시를 빈 값으로 덮어쓰지 않는 것**이 핵심이다.
  Future<bool> refresh(String spaceId) async {
    try {
      await _db.replaceSprints(spaceId, await _api.list(spaceId));
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<Sprint?> create(
    String spaceId, {
    required String name,
    String? goal,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    try {
      final created = await _api.create(
        spaceId,
        name: name,
        goal: goal,
        startsAt: startsAt,
        endsAt: endsAt,
      );
      await _db.upsertSprint(spaceId, created);
      return created;
    } on ApiException {
      return null;
    }
  }

  /// 상태를 바꾼다. `active` 로 바꿀 때 이미 도는 것이 있으면 서버가 409 를
  /// 주고, 여기서는 `null` 이 된다 — 화면이 그 뜻을 문구로 말한다.
  Future<Sprint?> setState(
    String spaceId,
    String sprintId,
    SprintState state,
  ) async {
    try {
      final updated = await _api.update(spaceId, sprintId, state: state);
      await _db.upsertSprint(spaceId, updated);
      return updated;
    } on ApiException {
      return null;
    }
  }

  /// 지우면 그 안의 이슈는 백로그로 돌아간다 — 서버가 `SetNull` 로 처리한다.
  Future<bool> remove(String spaceId, String sprintId) async {
    try {
      await _api.remove(spaceId, sprintId);
      await _db.deleteSprint(sprintId);
      return true;
    } on ApiException {
      return false;
    }
  }

  /// 기간이 없으면 서버가 400 이라 `null` 이 된다.
  Future<Burndown?> burndown(String spaceId, String sprintId) async {
    try {
      return await _api.burndown(spaceId, sprintId);
    } on ApiException {
      return null;
    }
  }

  Sprint _toSprint(CachedSprint r) => Sprint(
    id: r.id,
    name: r.name,
    goal: r.goal,
    startsAt: r.startsAt,
    endsAt: r.endsAt,
    // 모르는 값이 오면 planned 로 떨어뜨린다 — 서버가 상태를 늘렸는데 앱이
    // 낡았을 때 목록이 비는 것보다 낫다.
    state: SprintState.values.firstWhere(
      (v) => v.name == r.state,
      orElse: () => SprintState.planned,
    ),
  );
}
