import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue.freezed.dart';
part 'issue.g.dart';

/// 보드 컬럼. **서버 enum 과 이름이 같아야 한다** — 다르면 목록이 통째로
/// 엉뚱한 컬럼에 들어간다. 커스텀 컬럼은 만들지 않기로 했다(설계 §3).
enum IssueStatus { backlog, doing, review, done }

enum IssuePriority { low, mid, high }

/// 스페이스가 공유하는 라벨. 색은 `#RRGGBB` 문자열이다.
@freezed
abstract class IssueLabel with _$IssueLabel {
  const factory IssueLabel({
    required String id,
    required String name,
    required String color,
  }) = _IssueLabel;

  factory IssueLabel.fromJson(Map<String, dynamic> json) =>
      _$IssueLabelFromJson(json);
}

/// 대화 → 이슈의 역방향 링크. **한 겹만 펼친다**(7-3 의 인용과 같은 규칙).
///
/// 원문이 소프트 삭제되면 `body` 가 비고 `deleted` 가 참이 된다 — 맥락은
/// 남기되 본문은 싣지 않는다. 그러지 않으면 소프트 삭제의 뜻이 없어진다.
@freezed
abstract class IssueOrigin with _$IssueOrigin {
  const factory IssueOrigin({
    required String id,
    required String channelId,
    String? body,
    required String authorName,
    @Default(false) bool deleted,
  }) = _IssueOrigin;

  factory IssueOrigin.fromJson(Map<String, dynamic> json) =>
      _$IssueOriginFromJson(json);
}

/// 이슈에 붙는 사람(지금은 담당자만). 서버가 요약만 준다.
@freezed
abstract class IssueAuthor with _$IssueAuthor {
  const factory IssueAuthor({
    required String id,
    required String name,
    String? avatarUrl,
  }) = _IssueAuthor;

  factory IssueAuthor.fromJson(Map<String, dynamic> json) =>
      _$IssueAuthorFromJson(json);
}

/// `GET /api/spaces/:spaceId/issues` 의 한 항목.
@freezed
abstract class Issue with _$Issue {
  const factory Issue({
    required String id,

    /// 사람이 대화에서 부르는 이름(`NEXUS-12`). 스페이스 안에서 유일하다.
    required String key,
    required String title,
    String? description,
    required IssueStatus status,
    required IssuePriority priority,
    IssueAuthor? assignee,
    String? sprintId,
    String? parentId,
    int? storyPoints,

    /// 서버가 **문자열**로 준다 — Decimal 을 double 로 받으면 정밀도가 깎인다.
    /// 앱은 정렬과 되돌려 보내기에만 쓰고 산술을 하지 않는다.
    required String position,

    @Default(<IssueLabel>[]) List<IssueLabel> labels,

    /// 이 이슈가 어느 대화에서 나왔는지. 없으면 보드에서 직접 만든 것이다.
    IssueOrigin? originMessage,

    /// 번다운의 유일한 입력. 상태 전이가 정하므로 앱이 보내지 않는다.
    DateTime? closedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Issue;

  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);
}
