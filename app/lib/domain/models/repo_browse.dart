import 'package:freezed_annotation/freezed_annotation.dart';

part 'repo_browse.freezed.dart';
part 'repo_browse.g.dart';

@freezed
abstract class RepoBranch with _$RepoBranch {
  const factory RepoBranch({
    required String name,
    @Default(false) bool protected,
  }) = _RepoBranch;

  factory RepoBranch.fromJson(Map<String, dynamic> json) =>
      _$RepoBranchFromJson(json);
}

/// 디렉터리 하나의 항목. **서버가 폴더를 먼저, 그 안에서 이름순으로 준다** —
/// 앱이 다시 정렬하지 않는다.
@freezed
abstract class TreeEntry with _$TreeEntry {
  const factory TreeEntry({
    required String name,
    required String path,
    required String type,
    int? size,
  }) = _TreeEntry;

  const TreeEntry._();

  factory TreeEntry.fromJson(Map<String, dynamic> json) =>
      _$TreeEntryFromJson(json);

  bool get isDir => type == 'dir';
}

/// 파일 하나. `content` 가 없으면 `omitted` 가 이유를 말한다.
@freezed
abstract class BlobView with _$BlobView {
  const factory BlobView({
    required String path,
    required int size,
    String? content,
    String? omitted,
  }) = _BlobView;

  const BlobView._();

  factory BlobView.fromJson(Map<String, dynamic> json) =>
      _$BlobViewFromJson(json);

  /// **셋을 다른 문구로 말한다** — 사용자가 할 수 있는 일이 다르다.
  /// 바이너리는 영영 못 보고, 큰 파일은 GitHub 에서 열면 되고,
  /// `unavailable` 은 우리가 나중에 폴백을 붙이면 풀린다 (설계 §2).
  String? get omittedMessage => switch (omitted) {
        null => null,
        'binary' => '미리 볼 수 없는 파일입니다',
        'too_large' => '파일이 큽니다 (${_readableSize(size)})',
        'unavailable' => 'GitHub 이 본문을 주지 않았습니다',
        // 서버가 갈래를 늘려도 화면이 빈 채로 남지 않는다.
        _ => '본문을 볼 수 없습니다',
      };
}

/// 파일 탐색기와 어긋나지 않게 1024 기준(KiB)으로 적는다 — 8-2 와 같다.
String _readableSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

/// 커밋 한 줄. **payload 에서 온 것과 GitHub 에서 온 것이 같은 모양이다** —
/// 다르게 보이면 사용자가 두 목록을 다른 것으로 읽는다 (설계 §2).
@freezed
abstract class CommitSummary with _$CommitSummary {
  const factory CommitSummary({
    required String sha,
    required String message,
    String? authorName,
    DateTime? committedAt,

    /// 바뀐 파일 수. **브랜치 이력에서는 `null`** 이다 — GitHub 목록 API 가
    /// 주지 않는다. 0 으로 두면 "안 바뀐 커밋"으로 읽힌다.
    int? changedCount,
  }) = _CommitSummary;

  const CommitSummary._();

  factory CommitSummary.fromJson(Map<String, dynamic> json) =>
      _$CommitSummaryFromJson(json);

  String get shortSha => sha.length <= 7 ? sha : sha.substring(0, 7);

  /// 제목 줄만. 본문까지 넣으면 목록이 문단이 된다(10-1 과 같은 규칙).
  String get title => message.split('\n').first.trim();
}

@freezed
abstract class ChangedFile with _$ChangedFile {
  const factory ChangedFile({
    required String path,
    required String status,
  }) = _ChangedFile;

  const ChangedFile._();

  factory ChangedFile.fromJson(Map<String, dynamic> json) =>
      _$ChangedFileFromJson(json);

  /// `renamed` · `copied` 는 서버가 `modified` 로 접어 보낸다.
  String get statusLabel => switch (status) {
        'added' => '추가',
        'removed' => '삭제',
        _ => '수정',
      };
}

@freezed
abstract class CommitDetail with _$CommitDetail {
  const factory CommitDetail({
    required String sha,
    required String message,
    String? authorName,
    DateTime? committedAt,
    @Default(<ChangedFile>[]) List<ChangedFile> files,
  }) = _CommitDetail;

  const CommitDetail._();

  factory CommitDetail.fromJson(Map<String, dynamic> json) =>
      _$CommitDetailFromJson(json);

  String get shortSha => sha.length <= 7 ? sha : sha.substring(0, 7);
  String get title => message.split('\n').first.trim();

  /// 제목 아래 본문. 없으면 빈 문자열이다.
  String get bodyText => message.split('\n').skip(1).join('\n').trim();
}

/// `repo-events/:eventId` 응답. `kind` 로 push · pr · other 가 갈린다 —
/// push 가 아닌 이벤트는 `commits` 가 비어 있다.
@freezed
abstract class RepoEventView with _$RepoEventView {
  const factory RepoEventView({
    required String kind, // push · pr · other
    required String repoId,
    String? repoFullPath,
    String? ref,
    int? number,
    @Default(<CommitSummary>[]) List<CommitSummary> commits,
  }) = _RepoEventView;

  factory RepoEventView.fromJson(Map<String, dynamic> json) =>
      _$RepoEventViewFromJson(json);
}
