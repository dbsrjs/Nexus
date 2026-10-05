
import '../../domain/models/connection.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// GitHub 계정 연결. **스페이스가 아니라 사용자 단위**라 경로에 spaceId 가 없다.
class ConnectionsApi {
  ConnectionsApi(this._client);

  final ApiClient _client;

  /// POST /api/me/connections/github/start → 브라우저로 열 주소.
  ///
  /// 서버 설정이 없으면 503 이다 — 앱이 고칠 수 있는 문제가 아니라
  /// `ApiFailure` 로 분류해 자기 문구를 쓴다.
  Future<String> startGithub() async {
    return guardApi(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/me/connections/github/start',
      );
      return res.data?['authorizeUrl'] as String? ?? '';
    });
  }

  /// GET /api/me/connections — 비어 있으면 "연결 안 됨"이다.
  Future<List<GithubConnection>> list() async {
    return guardApi(() async {
      final res = await _client.dio.get<List<dynamic>>('/me/connections');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(GithubConnection.fromJson)
          .toList(growable: false);
    });
  }

  /// DELETE /api/me/connections/github — 이미 걸린 웹훅은 남는다.
  Future<void> disconnectGithub() async {
    return guardApi(() async {
      await _client.dio.delete<void>('/me/connections/github');
    });
  }
}
