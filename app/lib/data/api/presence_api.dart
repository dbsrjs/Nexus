
import '../../domain/models/presence.dart';
import 'api_client.dart';
import 'api_failure.dart';

class PresenceApi {
  PresenceApi(this._client);

  final ApiClient _client;

  /// GET /api/spaces/:spaceId/presence — 이 스페이스 멤버 중 오프라인이 아닌 사람(17단계 D19).
  Future<Map<String, Presence>> snapshot(String spaceId) async {
    return guardApi(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/presence',
      );
      final users =
          (res.data?['users'] as Map?)?.cast<String, Object?>() ?? const {};
      return {
        for (final e in users.entries)
          if (presenceFromWire(e.value) != Presence.offline)
            e.key: presenceFromWire(e.value),
      };
    });
  }
}
