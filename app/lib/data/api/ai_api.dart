import 'package:dio/dio.dart';

import '../../domain/models/ai_run.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// AI 실행. **결과는 캐시하지 않는다** — 일회성이라 drift 에 넣을 것이 없다
/// (설계 §11, 8-2 의 attachment_draft 선례).
class AiApi {
  AiApi(this._client);

  final ApiClient _client;

  /// POST /api/spaces/:spaceId/ai/summarize — 요약을 적재하고 `runId` 를
  /// 돌려준다. **캐시 적중이면 곧바로 done 이지만 그 구분은 호출자가
  /// `getRun` 으로 본다** — 두 경로를 하나로 둔다.
  Future<String> summarize({
    required String spaceId,
    required String channelId,
    required List<String> messageIds,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/spaces/$spaceId/ai/summarize',
        data: {'channelId': channelId, 'messageIds': messageIds},
      );
      return res.data!['runId'] as String;
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// GET /api/spaces/:spaceId/ai/runs/:runId
  Future<AiRun> getRun(String spaceId, String runId) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/ai/runs/$runId',
      );
      return AiRun.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }
}
