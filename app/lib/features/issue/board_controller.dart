import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/issues_api.dart';
import '../../data/repositories/issue_repository.dart';
import '../../domain/models/issue.dart';
import '../auth/auth_controller.dart';
import '../space/space_controller.dart';

final issuesApiProvider = Provider<IssuesApi>(
  (ref) => IssuesApi(ref.watch(apiClientProvider)),
);

final issueRepositoryProvider = Provider<IssueRepository>(
  (ref) => IssueRepository(
    api: ref.watch(issuesApiProvider),
    db: ref.watch(appDatabaseProvider),
  ),
);

/// 캐시를 구독한다. REST 든 소켓이든 캐시를 거쳐 여기로 온다 —
/// 한 화면이 두 공급원을 보면 회복되지 않는 틈이 생긴다(6-1 에서 겪었다).
final issueListProvider = StreamProvider<List<Issue>>((ref) {
  final spaceId = ref.watch(currentSpaceIdProvider);
  if (spaceId == null) return Stream.value(const []);
  return ref.watch(issueRepositoryProvider).watchIssues(spaceId);
});

/// 컬럼별 상한(200)에 걸려 잘린 컬럼. 화면이 "더 있다"를 말하는 데 쓴다.
/// 조용히 자르면 다 봤다고 오해한다.
class TruncatedColumns extends Notifier<List<IssueStatus>> {
  @override
  List<IssueStatus> build() => const [];

  void set(List<IssueStatus> value) => state = value;
}

final truncatedColumnsProvider =
    NotifierProvider<TruncatedColumns, List<IssueStatus>>(TruncatedColumns.new);

/// 상태별로 묶는다. **빈 컬럼도 자리를 지킨다** — 사라지면 거기로 옮길 수 없다.
final boardProvider = Provider<Map<IssueStatus, List<Issue>>>((ref) {
  final issues = ref.watch(issueListProvider).value ?? const <Issue>[];
  final board = {for (final s in IssueStatus.values) s: <Issue>[]};
  for (final issue in issues) {
    board[issue.status]!.add(issue);
  }
  return board;
});

/// 화면이 부르는 동작들. 실패를 `false`/`null` 로 돌려주고 화면이 문구를 정한다 —
/// 서버 문구를 그대로 쓰면 서버가 바뀔 때마다 앱 UX 가 흔들린다.
class BoardActions {
  BoardActions(this._ref);

  final Ref _ref;

  Future<bool> refresh() async {
    final spaceId = _ref.read(currentSpaceIdProvider);
    if (spaceId == null) return false;
    final truncated = await _ref.read(issueRepositoryProvider).refreshIssues(spaceId);
    if (truncated == null) return false;
    _ref.read(truncatedColumnsProvider.notifier).set(truncated);
    return true;
  }

  Future<bool> create({
    required String title,
    String? description,
    IssueStatus? status,
    IssuePriority? priority,
    String? originMessageId,
  }) async {
    final spaceId = _ref.read(currentSpaceIdProvider);
    if (spaceId == null) return false;
    final created = await _ref
        .read(issueRepositoryProvider)
        .create(
          spaceId,
          title: title,
          description: description,
          status: status,
          priority: priority,
          originMessageId: originMessageId,
        );
    return created != null;
  }

  Future<bool> moveTo(Issue issue, IssueStatus status) async {
    final spaceId = _ref.read(currentSpaceIdProvider);
    if (spaceId == null) return false;
    return _ref.read(issueRepositoryProvider).moveTo(spaceId, issue, status);
  }
}

final boardActionsProvider = Provider<BoardActions>(BoardActions.new);

/// 컬럼 이름. enum 이름을 그대로 보이면 영어가 새 나간다.
String issueStatusLabel(IssueStatus status) => switch (status) {
  IssueStatus.backlog => '백로그',
  IssueStatus.doing => '진행',
  IssueStatus.review => '검토',
  IssueStatus.done => '완료',
};

String issuePriorityLabel(IssuePriority priority) => switch (priority) {
  IssuePriority.low => '낮음',
  IssuePriority.mid => '보통',
  IssuePriority.high => '높음',
};
