import 'package:dio/dio.dart';

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
    try {
      final res = await _client.dio.get<List<dynamic>>(
        '/spaces/$spaceId/members',
      );
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(SpaceMemberProfile.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }
}
