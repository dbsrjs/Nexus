
import '../../domain/models/space.dart';
import 'api_client.dart';
import 'api_failure.dart';

class SpacesApi {
  SpacesApi(this._client);

  final ApiClient _client;

  /// GET /api/spaces — 내가 속한 스페이스만 돌아온다.
  ///
  /// 서버는 전역 목록을 주지 않는다. 남의 스페이스는 조회 자체가 되지 않는다
  /// (docs/백엔드-설계.md §2).
  Future<List<Space>> list() async {
    return guardApi(() async {
      final res = await _client.dio.get<List<dynamic>>('/spaces');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Space.fromJson)
          .toList(growable: false);
    });
  }

  /// POST /api/spaces — 만든 사람은 owner 다. 응답에 역할이 없어 채워 넣는다.
  Future<Space> create(String name) async {
    return guardApi(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/spaces',
        data: {'name': name},
      );
      return Space.fromJson({...res.data!, 'role': SpaceRole.owner.wire});
    });
  }

  /// PATCH /api/spaces/:spaceId (admin+) — 준 값만 바꾼다(이름 · 스프린트 스위치).
  Future<void> update(
    String spaceId, {
    String? name,
    bool? sprintsEnabled,
  }) async {
    return guardApi(() async {
      await _client.dio.patch<void>(
        '/spaces/$spaceId',
        data: {'name': ?name, 'sprintsEnabled': ?sprintsEnabled},
      );
    });
  }

  /// POST /api/spaces/:spaceId/leave — owner 는 403(앱은 메뉴를 감춘다).
  Future<void> leave(String spaceId) async {
    return guardApi(() async {
      await _client.dio.post<void>('/spaces/$spaceId/leave');
    });
  }
}
