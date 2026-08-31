import 'package:dio/dio.dart';

import '../../domain/models/pull.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// PR 열람. **캐시하지 않는다** — 저장소 열람 · 이슈 댓글과 같은 취급이다.
class PullsApi {
  PullsApi(this._client);

  final ApiClient _client;

  Future<({List<PullSummary> pulls, int? nextPage})> list(
    String spaceId,
    String repoId, {
    String state = 'open',
    int page = 1,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/repos/$repoId/pulls',
        queryParameters: {'state': state, 'page': page},
      );
      final raw = (res.data?['pulls'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      return (
        pulls: raw.map(PullSummary.fromJson).toList(growable: false),
        nextPage: res.data?['nextPage'] as int?,
      );
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  Future<PullDetail> detail(String spaceId, String repoId, int number) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/repos/$repoId/pulls/$number',
      );
      return PullDetail.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  Future<({List<PullChangedFile> files, bool truncated})> files(
    String spaceId,
    String repoId,
    int number,
  ) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/repos/$repoId/pulls/$number/files',
      );
      final raw = (res.data?['files'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      return (
        files: raw.map(PullChangedFile.fromJson).toList(growable: false),
        truncated: res.data?['truncated'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }
}
