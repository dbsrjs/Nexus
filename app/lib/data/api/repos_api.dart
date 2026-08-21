import 'package:dio/dio.dart';

import '../../domain/models/repo.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// 저장소 연동. 목록만 사용자 단위(`/me/github/repos`)이고 나머지는
/// 스페이스 밑이다 — 토큰은 사람에게, 저장소는 스페이스에 붙는다.
class ReposApi {
  ReposApi(this._client);

  final ApiClient _client;

  /// 내 GitHub 저장소 한 페이지. **검색은 앱이 받아 온 목록 안에서 한다**
  /// — 서버에 검색이 없다 (설계 §6).
  Future<({List<GithubRepo> repos, bool hasNext})> myGithubRepos(int page) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/me/github/repos',
        queryParameters: {'page': page},
      );
      final raw = (res.data?['repos'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      return (
        repos: raw.map(GithubRepo.fromJson).toList(growable: false),
        hasNext: res.data?['hasNext'] == true,
      );
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  Future<List<SpaceRepo>> spaceRepos(String spaceId) async {
    try {
      final res = await _client.dio.get<List<dynamic>>('/spaces/$spaceId/repos');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(SpaceRepo.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// 붙이고 훅을 건다. **숫자 id 만 보낸다** — 이름과 권한은 서버가 GitHub 에
  /// 물어 확인한다.
  Future<SpaceRepo> connect(
    String spaceId, {
    required int githubRepoId,
    String? linkedChannelId,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/spaces/$spaceId/repos/connect',
        data: {
          'githubRepoId': githubRepoId,
          // 채널을 안 고르면 키 자체를 싣지 않는다 — 서버가 "안 보냄"과
          // "null 로 보냄"을 구분한다(승격 때 기존 채널을 떼지 않는다).
          'linkedChannelId': ?linkedChannelId,
        },
      );
      return SpaceRepo.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// 훅을 다시 건다. 주소가 바뀌었거나 등록에 실패했던 행에 쓴다.
  Future<SpaceRepo> reattach(String spaceId, String repoId) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/spaces/$spaceId/repos/$repoId/webhook',
      );
      return SpaceRepo.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  Future<void> remove(String spaceId, String repoId) async {
    try {
      await _client.dio.delete<void>('/spaces/$spaceId/repos/$repoId');
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }
}
