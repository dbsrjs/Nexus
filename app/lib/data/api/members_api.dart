
import '../../domain/models/space.dart';
import '../../domain/models/space_member.dart';
import 'api_client.dart';
import 'api_failure.dart';

class MembersApi {
  MembersApi(this._client);

  final ApiClient _client;

  /// GET /api/spaces/:spaceId/members
  ///
  /// 멘션 자동완성이 이 목록을 쓴다. 서버가 본문에 `<@userId>` 형식을 요구하므로
  /// **앱이 이름 → id 를 이어 주는 다리**가 필요하다.
  Future<List<SpaceMemberProfile>> list(String spaceId) async {
    return guardApi(() async {
      final res = await _client.dio.get<List<dynamic>>(
        '/spaces/$spaceId/members',
      );
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(SpaceMemberProfile.fromJson)
          .toList(growable: false);
    });
  }

  /// PATCH /api/spaces/:spaceId/members/:userId (admin+, 나보다 낮은 사람만)
  Future<void> updateRole(String spaceId, String userId, SpaceRole role) async {
    return guardApi(() async {
      await _client.dio.patch<void>(
        '/spaces/$spaceId/members/$userId',
        data: {'role': role.wire},
      );
    });
  }

  /// DELETE /api/spaces/:spaceId/members/:userId (admin+, 나보다 낮은 사람만)
  Future<void> remove(String spaceId, String userId) async {
    return guardApi(() async {
      await _client.dio.delete<void>('/spaces/$spaceId/members/$userId');
    });
  }
}
