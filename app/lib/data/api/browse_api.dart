import 'package:dio/dio.dart';

import '../../domain/models/repo_browse.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// 저장소 열람. **캐시하지 않는다**(설계 §3) — 서버도 캐시하지 않는다.
class BrowseApi {
  BrowseApi(this._client);

  final ApiClient _client;

  Future<({List<RepoBranch> branches, String? defaultBranch})> branches(
    String spaceId,
    String repoId,
  ) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/repos/$repoId/branches',
      );
      final raw = (res.data?['branches'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      return (
        branches: raw.map(RepoBranch.fromJson).toList(growable: false),
        defaultBranch: res.data?['defaultBranch'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// `path` 를 비우면 루트, `ref` 를 비우면 기본 브랜치다.
  Future<({String ref, List<TreeEntry> entries})> tree(
    String spaceId,
    String repoId, {
    required String ref,
    required String path,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/repos/$repoId/tree',
        queryParameters: {'ref': ref, 'path': path},
      );
      final raw = (res.data?['entries'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      return (
        ref: res.data?['ref'] as String? ?? ref,
        entries: raw.map(TreeEntry.fromJson).toList(growable: false),
      );
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  Future<BlobView> blob(
    String spaceId,
    String repoId, {
    required String ref,
    required String path,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/repos/$repoId/blob',
        queryParameters: {'ref': ref, 'path': path},
      );
      return BlobView.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }
}
