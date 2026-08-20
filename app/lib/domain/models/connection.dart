import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection.freezed.dart';
part 'connection.g.dart';

/// `GET /api/me/connections` 의 한 항목.
///
/// **토큰은 여기 없다.** 서버가 어떤 응답에도 싣지 않는다
/// (docs/superpowers/specs/2026-08-20-github-oauth-design.md §4).
@freezed
abstract class GithubConnection with _$GithubConnection {
  const factory GithubConnection({
    required String provider,
    required String login,
    String? avatarUrl,
    required DateTime connectedAt,
  }) = _GithubConnection;

  factory GithubConnection.fromJson(Map<String, dynamic> json) =>
      _$GithubConnectionFromJson(json);
}
