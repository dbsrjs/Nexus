import 'package:freezed_annotation/freezed_annotation.dart';

part 'pull.freezed.dart';
part 'pull.g.dart';

/// PR 의 상태. **머지와 그냥 닫힘은 사람에게 전혀 다른 일이라 갈라 둔다.**
enum PullState { open, merged, closed }

/// 리뷰를 접은 값. **`null` 은 `pending` 이 아니라 "그릴 것이 없음"이다.**
enum PullReviewState {
  approved,
  @JsonValue('changes_requested')
  changesRequested,
}

@freezed
abstract class PullSummary with _$PullSummary {
  const factory PullSummary({
    required int number,
    required String title,
    required PullState state,
    @Default(false) bool draft,
    String? authorLogin,
    String? authorAvatarUrl,
    String? sourceBranch,
    /// **파일을 열 때 쓰는 것은 브랜치가 아니라 이 sha 다.** 포크에서 온
    /// PR 의 `sourceBranch` 는 포크 쪽 브랜치라 우리가 붙인 저장소에는 없어
    /// 404 가 된다(진짜 GitHub 으로 확인했다).
    String? headSha,
    String? targetBranch,
    String? htmlUrl,
    String? openedAt,
    String? mergedAt,
    String? closedAt,
  }) = _PullSummary;

  factory PullSummary.fromJson(Map<String, dynamic> json) =>
      _$PullSummaryFromJson(json);
}

@freezed
abstract class PullDetail with _$PullDetail {
  const factory PullDetail({
    required int number,
    required String title,
    required PullState state,
    @Default(false) bool draft,
    String? body,
    String? authorLogin,
    String? authorAvatarUrl,
    String? sourceBranch,
    /// **파일을 열 때 쓰는 것은 브랜치가 아니라 이 sha 다.** 포크에서 온
    /// PR 의 `sourceBranch` 는 포크 쪽 브랜치라 우리가 붙인 저장소에는 없어
    /// 404 가 된다(진짜 GitHub 으로 확인했다).
    String? headSha,
    String? targetBranch,
    String? htmlUrl,
    String? openedAt,
    String? mergedAt,
    String? closedAt,
    /// **서버가 모르면 `null` 이다.** 0 으로 두면 "안 바뀐 PR"로 읽힌다.
    int? additions,
    int? deletions,
    int? changedFiles,
    PullReviewState? review,
  }) = _PullDetail;

  factory PullDetail.fromJson(Map<String, dynamic> json) =>
      _$PullDetailFromJson(json);
}

@freezed
abstract class PullChangedFile with _$PullChangedFile {
  const factory PullChangedFile({
    required String path,
    required String status,
    @Default(0) int additions,
    @Default(0) int deletions,
    String? previousPath,
  }) = _PullChangedFile;

  factory PullChangedFile.fromJson(Map<String, dynamic> json) =>
      _$PullChangedFileFromJson(json);
}
