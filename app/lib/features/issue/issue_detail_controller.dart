import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/issue.dart';
import '../../domain/models/issue_comment.dart';
import '../space/space_controller.dart';
import 'board_controller.dart';

/// 지금 열려 있는 이슈의 키(`NEXUS-12`). 라우트가 진실의 원천이고
/// 상세 화면이 이 값을 실어 준다.
class CurrentIssueKey extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? key) => state = key;
}

final currentIssueKeyProvider =
    NotifierProvider<CurrentIssueKey, String?>(CurrentIssueKey.new);

/// **본문은 캐시에서 그린다.** 보드를 거쳐 들어왔으면 이미 캐시에 있어
/// 상세를 열자마자 보인다(오프라인에서도).
///
/// 딥링크로 곧장 들어와 캐시가 비어 있을 때만 서버에 한 건을 묻는다.
final currentIssueProvider = FutureProvider.autoDispose<Issue?>((ref) async {
  final spaceId = ref.watch(currentSpaceIdProvider);
  final key = ref.watch(currentIssueKeyProvider);
  if (spaceId == null || key == null) return null;

  // 보드 캐시가 갱신되면 상세도 따라 갱신되도록 스트림을 구독한다.
  ref.watch(issueListProvider);

  final repo = ref.watch(issueRepositoryProvider);
  return await repo.findCachedByKey(spaceId, key) ??
      await repo.fetchByKey(spaceId, key);
});

/// 댓글은 캐시하지 않는다 — 들어올 때마다 받는다(설계 §6-1).
final issueCommentsProvider =
    FutureProvider.autoDispose<List<IssueComment>>((ref) async {
      final spaceId = ref.watch(currentSpaceIdProvider);
      final issue = await ref.watch(currentIssueProvider.future);
      if (spaceId == null || issue == null) return const [];
      return ref.watch(issueRepositoryProvider).listComments(spaceId, issue.id);
    });

/// 상세 화면이 부르는 동작들. 실패를 값으로 돌려주고 화면이 문구를 정한다.
class IssueDetailActions {
  IssueDetailActions(this._ref);

  final Ref _ref;

  Future<bool> comment(String issueId, String body) async {
    final spaceId = _ref.read(currentSpaceIdProvider);
    if (spaceId == null) return false;

    final created = await _ref
        .read(issueRepositoryProvider)
        .createComment(spaceId, issueId, body);
    if (created == null) return false;

    // 캐시하지 않으므로 다시 받는다. 목록이 몇 건 수준이라 값이 싸다.
    _ref.invalidate(issueCommentsProvider);
    return true;
  }

  Future<bool> remove(String issueId) async {
    final spaceId = _ref.read(currentSpaceIdProvider);
    if (spaceId == null) return false;
    return _ref.read(issueRepositoryProvider).remove(spaceId, issueId);
  }
}

final issueDetailActionsProvider = Provider<IssueDetailActions>(
  IssueDetailActions.new,
);
