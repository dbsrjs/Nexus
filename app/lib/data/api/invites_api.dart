
import '../../domain/models/invite.dart';
import '../../domain/models/space.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// 초대(16단계). 수락만 스페이스 밖 주소(`/invites/:code/accept`)다 — 아직 멤버가 아니다.
class InvitesApi {
  InvitesApi(this._client);

  final ApiClient _client;

  /// POST /api/spaces/:spaceId/invites (admin+). 비운 값은 무제한 · 무기한이다.
  Future<Invite> create(
    String spaceId, {
    required SpaceRole role,
    int? expiresInHours,
    int? maxUses,
  }) => guardApi(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/spaces/$spaceId/invites',
      data: {
        'role': role.wire,
        'expiresInHours': ?expiresInHours,
        'maxUses': ?maxUses,
      },
    );
    return Invite.fromJson(res.data!);
  });

  /// GET /api/spaces/:spaceId/invites (admin+) — 아직 쓸 수 있는 것만.
  Future<List<Invite>> list(String spaceId) => guardApi(() async {
    final res = await _client.dio.get<List<dynamic>>(
      '/spaces/$spaceId/invites',
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(Invite.fromJson)
        .toList(growable: false);
  });

  /// DELETE /api/spaces/:spaceId/invites/:inviteId (admin+)
  Future<void> revoke(String spaceId, String inviteId) => guardApi(
    () => _client.dio.delete<void>('/spaces/$spaceId/invites/$inviteId'),
  );

  /// POST /api/invites/:code/accept — 들어간 스페이스의 id.
  ///
  /// 응답의 스페이스에는 내 역할이 없다. 부르는 쪽은 목록을 다시 받은 뒤 이 id 로 들어간다.
  Future<String> accept(String code) => guardApi(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/invites/$code/accept',
    );
    return res.data!['id'] as String;
  });
}
