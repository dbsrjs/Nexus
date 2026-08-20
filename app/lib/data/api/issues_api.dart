import 'package:dio/dio.dart';

import '../../domain/models/issue.dart';
import '../../domain/models/issue_comment.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// 목록 응답. `truncated` 는 컬럼별 상한(200)에 걸려 잘린 컬럼이다 —
/// 화면이 "더 있다"를 말할 수 있어야 한다. 조용히 자르면 다 왔다고 오해한다.
class IssuePage {
  const IssuePage({required this.issues, required this.truncated});

  const IssuePage.empty() : issues = const [], truncated = const [];

  final List<Issue> issues;
  final List<IssueStatus> truncated;
}

class IssuesApi {
  IssuesApi(this._client);

  final ApiClient _client;

  /// GET /api/spaces/:spaceId/issues
  Future<IssuePage> list(String spaceId) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/issues',
      );
      final data = res.data ?? const <String, dynamic>{};
      return IssuePage(
        issues: (data['issues'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(Issue.fromJson)
            .toList(growable: false),
        truncated: (data['truncated'] as List<dynamic>? ?? const [])
            .map((v) => IssueStatus.values.byName(v as String))
            .toList(growable: false),
      );
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// POST /api/spaces/:spaceId/issues — 만들면 그 컬럼 맨 위에 놓인다.
  Future<Issue> create(
    String spaceId, {
    required String title,
    String? description,
    IssueStatus? status,
    IssuePriority? priority,
    String? assigneeId,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/spaces/$spaceId/issues',
        data: {
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (status != null) 'status': status.name,
          if (priority != null) 'priority': priority.name,
          'assigneeId': ?assigneeId,
        },
      );
      return Issue.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// PATCH /api/spaces/:spaceId/issues/:issueId
  ///
  /// `status` 를 주면 **컬럼만** 옮긴다 — 대상 컬럼 맨 위로 간다. 카드 메뉴가
  /// 쓰는 길이다(메뉴는 어느 카드 사이에 넣을지 모른다).
  Future<Issue> update(
    String spaceId,
    String issueId, {
    IssueStatus? status,
    String? title,
    IssuePriority? priority,
  }) async {
    try {
      final res = await _client.dio.patch<Map<String, dynamic>>(
        '/spaces/$spaceId/issues/$issueId',
        data: {
          if (status != null) 'status': status.name,
          'title': ?title,
          if (priority != null) 'priority': priority.name,
        },
      );
      return Issue.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// GET /api/spaces/:spaceId/issues?key=NEXUS-12 — 딥링크로 상세에 곧장
  /// 들어왔는데 캐시가 비어 있을 때 한 건만 받아 온다.
  Future<Issue?> findByKey(String spaceId, String key) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/issues',
        queryParameters: {'key': key},
      );
      final issues = (res.data?['issues'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      return issues.isEmpty ? null : Issue.fromJson(issues.first);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// DELETE /api/spaces/:spaceId/issues/:issueId — **하드 삭제**다.
  Future<void> remove(String spaceId, String issueId) async {
    try {
      await _client.dio.delete<void>('/spaces/$spaceId/issues/$issueId');
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// GET /api/spaces/:spaceId/issues/:issueId/comments — 오래된 것부터.
  Future<List<IssueComment>> listComments(String spaceId, String issueId) async {
    try {
      final res = await _client.dio.get<List<dynamic>>(
        '/spaces/$spaceId/issues/$issueId/comments',
      );
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(IssueComment.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// POST /api/spaces/:spaceId/issues/:issueId/comments
  Future<IssueComment> createComment(
    String spaceId,
    String issueId,
    String body,
  ) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/spaces/$spaceId/issues/$issueId/comments',
        data: {'body': body},
      );
      return IssueComment.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// PUT /api/spaces/:spaceId/issues/:issueId/position — 자리까지 정한다.
  /// 드래그가 붙을 자리이고, 9-1 화면에서는 아직 쓰지 않는다.
  Future<Issue> move(
    String spaceId,
    String issueId, {
    required IssueStatus status,
    String? afterId,
    String? beforeId,
  }) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/spaces/$spaceId/issues/$issueId/position',
        data: {
          'status': status.name,
          'afterId': ?afterId,
          'beforeId': ?beforeId,
        },
      );
      return Issue.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }
}
