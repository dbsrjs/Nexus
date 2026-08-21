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
