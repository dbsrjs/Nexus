import 'package:dio/dio.dart';

import '../../domain/models/sprint.dart';
import 'api_client.dart';
import 'api_failure.dart';

class SprintsApi {
  SprintsApi(this._client);

  final ApiClient _client;

  /// GET /api/spaces/:spaceId/sprints — 도는 것이 먼저, 닫힌 것은 뒤로.
  Future<List<Sprint>> list(String spaceId) async {
    try {
      final res = await _client.dio.get<List<dynamic>>(
        '/spaces/$spaceId/sprints',
      );
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Sprint.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// POST /api/spaces/:spaceId/sprints — 만들면 `planned` 다.
  Future<Sprint> create(
    String spaceId, {
    required String name,
    String? goal,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/spaces/$spaceId/sprints',
        data: {
          'name': name,
          if (goal != null && goal.isNotEmpty) 'goal': goal,
          if (startsAt != null) 'startsAt': startsAt.toUtc().toIso8601String(),
          if (endsAt != null) 'endsAt': endsAt.toUtc().toIso8601String(),
        },
      );
      return Sprint.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// PATCH /api/spaces/:spaceId/sprints/:sprintId
  ///
  /// `state` 를 `active` 로 바꿀 때 이미 도는 것이 있으면 서버가 409 를 준다 —
  /// 스페이스당 하나이기 때문이다.
  Future<Sprint> update(
    String spaceId,
    String sprintId, {
    SprintState? state,
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    try {
      final res = await _client.dio.patch<Map<String, dynamic>>(
        '/spaces/$spaceId/sprints/$sprintId',
        data: {
          if (state != null) 'state': state.name,
          'name': ?name,
          if (startsAt != null) 'startsAt': startsAt.toUtc().toIso8601String(),
          if (endsAt != null) 'endsAt': endsAt.toUtc().toIso8601String(),
        },
      );
      return Sprint.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// DELETE — 지우면 그 안의 이슈는 **백로그로 돌아간다**(사라지지 않는다).
  Future<void> remove(String spaceId, String sprintId) async {
    try {
      await _client.dio.delete<void>('/spaces/$spaceId/sprints/$sprintId');
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// GET .../burndown — 기간이 없으면 서버가 400 이다.
  Future<Burndown> burndown(String spaceId, String sprintId) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/sprints/$sprintId/burndown',
      );
      return Burndown.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }
}
