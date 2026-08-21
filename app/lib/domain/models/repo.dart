import 'package:freezed_annotation/freezed_annotation.dart';

part 'repo.freezed.dart';
part 'repo.g.dart';

/// 고를 수 있는 내 GitHub 저장소. **캐시하지 않는다** — 원본이 GitHub 이고
/// 사본을 두면 곧바로 어긋난다 (설계 §9).
@freezed
abstract class GithubRepo with _$GithubRepo {
  const factory GithubRepo({
    required int id,
    required String fullName,
    @Default(false) bool private,
    String? defaultBranch,
    DateTime? pushedAt,

    /// 훅을 걸 권한. **false 면 고를 수 없게 그린다** — 눌러 봐야 403 이다.
    @Default(false) bool canWebhook,
  }) = _GithubRepo;

  factory GithubRepo.fromJson(Map<String, dynamic> json) =>
      _$GithubRepoFromJson(json);
}

/// 이 스페이스에 붙은 저장소.
@freezed
abstract class SpaceRepo with _$SpaceRepo {
  const factory SpaceRepo({
    required String id,
    required String name,
    required String fullPath,
    String? linkedChannelId,

    /// GitHub 이 준 훅 id. **없으면 훅이 안 걸린 것**이다 — 등록에 실패했거나
    /// 수동으로 붙인 행이다.
    String? webhookExternalId,
  }) = _SpaceRepo;

  const SpaceRepo._();

  factory SpaceRepo.fromJson(Map<String, dynamic> json) =>
      _$SpaceRepoFromJson(json);

  bool get webhookActive => webhookExternalId != null;
}
