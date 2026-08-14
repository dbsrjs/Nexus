import 'package:dio/dio.dart';

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
    try {
      final res = await _client.dio.get<List<dynamic>>('/spaces');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Space.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }
}
