import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue.dart';

part 'issue_comment.freezed.dart';
part 'issue_comment.g.dart';

/// 이슈 댓글. **캐시하지 않는다** — 파일 목록과 같은 판단이다.
///
/// 이슈 상세는 자주 여는 화면이 아니고, 오프라인에서 댓글을 읽어야 할 이유가
/// 약하다. 캐시하지 않으므로 실시간 이벤트도 두지 않았다(설계 §6-1).
@freezed
abstract class IssueComment with _$IssueComment {
  const factory IssueComment({
    required String id,
    required String issueId,
    required String body,
    required IssueAuthor author,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _IssueComment;

  factory IssueComment.fromJson(Map<String, dynamic> json) =>
      _$IssueCommentFromJson(json);
}
