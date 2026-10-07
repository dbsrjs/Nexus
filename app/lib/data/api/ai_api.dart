
import '../../domain/models/ai_run.dart';
import '../../domain/models/ai_thread.dart';
import '../../features/ai/ai_request.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// AI 실행. **결과는 캐시하지 않는다** — 일회성이라 drift 에 넣을 것이 없다
/// (설계 §11, 8-2 의 attachment_draft 선례).
class AiApi {
  AiApi(this._client);

  final ApiClient _client;

  /// POST /api/spaces/:spaceId/ai/ask — 요청을 적재하고 `runId` 를
  /// 돌려준다. **캐시 적중이면 곧바로 done 이지만 그 구분은 호출자가
  /// `getRun` 으로 본다** — 두 경로를 하나로 둔다.
  Future<String> ask(String spaceId, AiRequest request) async {
    return guardApi(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/spaces/$spaceId/ai/ask',
        data: request.toJson(),
      );
      return res.data!['runId'] as String;
    });
  }

  /// GET /api/spaces/:spaceId/ai/runs/:runId
  Future<AiRun> getRun(String spaceId, String runId) async {
    return guardApi(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/ai/runs/$runId',
      );
      return AiRun.fromJson(res.data!);
    });
  }

  /// GET /api/spaces/:spaceId/ai/threads — 지난 대화(19). 끝 답이 늦은 것부터.
  /// **캐시하지 않는다** — 패널을 열 때마다 새로 읽는다(설계 D13).
  Future<AiThreadPage> listThreads(String spaceId, {String? cursor}) async {
    return guardApi(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/ai/threads',
        queryParameters: {'cursor': ?cursor},
      );
      return AiThreadPage.fromJson(res.data!);
    });
  }

  /// GET /api/spaces/:spaceId/ai/threads/:rootRunId — 뿌리부터 끝까지.
  Future<AiThread> getThread(String spaceId, String rootRunId) async {
    return guardApi(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/spaces/$spaceId/ai/threads/$rootRunId',
      );
      return AiThread.fromJson(res.data!);
    });
  }
}
