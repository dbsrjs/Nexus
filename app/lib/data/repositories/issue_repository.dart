import '../../domain/models/issue.dart';
import '../../domain/models/issue_comment.dart';
import '../api/api_failure.dart';
import '../api/issues_api.dart';
import '../local/app_database.dart';

/// 이슈 보드의 캐시. 대화와 같은 규칙이다 —
/// **화면은 drift 를 구독하고, REST 와 소켓은 캐시를 갱신할 뿐이다.**
///
/// 다만 대화와 달리 **전송 큐가 없다.** 오프라인에서 만든 이슈를 모아 두었다가
/// 내보내지 않는다는 뜻이다. 메시지는 append 라 나중에 흘려보내도 순서만 맞으면
/// 되지만, 칸반 이동은 같은 카드를 두 곳에서 옮겼을 때 **합칠 방법이 없다.**
class IssueRepository {
  IssueRepository({required IssuesApi api, required AppDatabase db})
    : _api = api,
      _db = db;

  final IssuesApi _api;
  final AppDatabase _db;

  /// 보드에 그릴 순서 그대로(컬럼 순 · position 순) 흘려준다.
  Stream<List<Issue>> watchIssues(String spaceId) =>
      _db.watchIssues(spaceId).map((rows) => rows.map(_toIssue).toList(growable: false));

  /// **실패를 던지지 않고 false 를 돌려준다.** 오프라인은 오류가 아니라 정상
  /// 경로다. 캐시를 빈 값으로 덮어쓰지 않는 것이 핵심이다.
  ///
  /// 잘린 컬럼(`truncated`)은 화면이 "더 있다"를 말하는 데 쓰므로 함께 준다.
  Future<List<IssueStatus>?> refreshIssues(String spaceId) async {
    try {
      final page = await _api.list(spaceId);
      await _db.replaceIssues(spaceId, page.issues);
      return page.truncated;
    } on ApiException {
      return null;
    }
  }

  /// 만들면 서버가 컬럼 맨 위에 놓아 준다. 큐에 넣지 않으므로 온라인에서만 된다.
  Future<Issue?> create(
    String spaceId, {
    required String title,
    String? description,
    IssueStatus? status,
    IssuePriority? priority,
  }) async {
    try {
      final created = await _api.create(
        spaceId,
        title: title,
        description: description,
        status: status,
        priority: priority,
      );
      await _db.upsertIssue(spaceId, created);
      return created;
    } on ApiException {
      return null;
    }
  }

  /// 낙관적으로 옮긴 뒤 실패하면 **서버가 알던 값으로 되돌린다.**
  /// 카드가 슬쩍 제자리로 돌아가는 것이 곧 실패 신호다.
  Future<bool> moveTo(String spaceId, Issue issue, IssueStatus status) async {
    if (issue.status == status) return true;

    await _db.upsertIssue(spaceId, issue.copyWith(status: status));
    try {
      final updated = await _api.update(spaceId, issue.id, status: status);
      await _db.upsertIssue(spaceId, updated);
      return true;
    } on ApiException {
      await _db.upsertIssue(spaceId, issue);
      return false;
    }
  }

  /// 캐시에서 키로 찾는다. 보드를 거쳐 들어왔으면 여기서 끝난다.
  Future<Issue?> findCachedByKey(String spaceId, String key) async {
    final rows = await _db.watchIssues(spaceId).first;
    for (final row in rows) {
      if (row.key == key) return _toIssue(row);
    }
    return null;
  }

  /// 캐시에 없을 때만 서버에 묻는다 — 딥링크로 상세에 곧장 들어온 경우다.
  Future<Issue?> fetchByKey(String spaceId, String key) async {
    try {
      final issue = await _api.findByKey(spaceId, key);
      if (issue != null) await _db.upsertIssue(spaceId, issue);
      return issue;
    } on ApiException {
      return null;
    }
  }

  /// **하드 삭제**다. 성공하면 캐시에서도 지운다 — 소켓이 오기 전에 화면이
  /// 먼저 반응해야 지운 사람이 기다리지 않는다.
  Future<bool> remove(String spaceId, String issueId) async {
    try {
      await _api.remove(spaceId, issueId);
      await _db.deleteIssue(issueId);
      return true;
    } on ApiException {
      return false;
    }
  }

  /// 댓글은 캐시하지 않는다. 들어올 때마다 받는다(설계 §6-1).
  Future<List<IssueComment>> listComments(String spaceId, String issueId) =>
      _api.listComments(spaceId, issueId);

  Future<IssueComment?> createComment(
    String spaceId,
    String issueId,
    String body,
  ) async {
    try {
      return await _api.createComment(spaceId, issueId, body);
    } on ApiException {
      return null;
    }
  }

  /// 소켓이 준 이슈를 캐시에 반영한다. `issue:created` 와 `issue:updated` 가
  /// 같은 일을 하므로 하나로 받는다 — 이름이 나뉘어 있어 앱은 "이 id 가
  /// 캐시에 있나"를 먼저 묻지 않아도 된다.
  Future<void> applyUpsert(String spaceId, Issue issue) =>
      _db.upsertIssue(spaceId, issue);

  Future<void> applyDelete(String issueId) => _db.deleteIssue(issueId);

  Issue _toIssue(CachedIssue r) => Issue(
    id: r.id,
    key: r.key,
    title: r.title,
    description: r.description,
    // 서버 enum 과 이름이 같다. 모르는 값이 오면 backlog 로 떨어뜨린다 —
    // 서버가 컬럼을 늘렸는데 앱이 낡았을 때 화면이 비는 것보다 낫다.
    status: IssueStatus.values.firstWhere(
      (v) => v.name == r.status,
      orElse: () => IssueStatus.backlog,
    ),
    priority: IssuePriority.values.firstWhere(
      (v) => v.name == r.priority,
      orElse: () => IssuePriority.mid,
    ),
    assignee: r.assigneeId == null
        ? null
        : IssueAuthor(
            id: r.assigneeId!,
            name: r.assigneeName ?? '',
            avatarUrl: r.assigneeAvatarUrl,
          ),
    sprintId: r.sprintId,
    parentId: r.parentId,
    storyPoints: r.storyPoints,
    position: r.position,
    closedAt: r.closedAt,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}
