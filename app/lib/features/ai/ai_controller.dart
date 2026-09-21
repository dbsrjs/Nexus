import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/ai_api.dart';
import '../../data/api/api_failure.dart';
import '../../data/socket/socket_event.dart';
import '../../domain/models/ai_run.dart';
import '../auth/auth_controller.dart';
import '../realtime/socket_controller.dart';

/// apiClientProvider 는 features/auth/auth_controller.dart 에 있다(다른
/// `*_api` provider 들과 같은 관례).
final aiApiProvider = Provider<AiApi>(
  (ref) => AiApi(ref.watch(apiClientProvider)),
);

/// 요약 실패를 화면 문구로. **서버 문구를 그대로 쓰지 않는다** — 종류만 받아
/// 앱이 자기 문구를 쓴다.
///
/// **새 enum 을 만들지 않고 `ApiFailure` 를 쓴다.** 그것이 이미 상태 코드를
/// 종류로 옮기는 유일한 지점이고(`classifyDioException`), `AiApi` 도 그것을
/// 통해 던진다. 여기서 필요한 것은 분류가 아니라 **이 화면의 문구**뿐이다.
///
/// `server` 에 「AI 를 쓸 수 없습니다」를 쓰는 이유: 503(미설정)과 500(진짜
/// 오류)이 `ApiFailure` 에서 같은 칸으로 접히는데, **사용자가 할 일이 어느
/// 쪽이든 같다** — 지금은 못 쓰고 나중에 다시 해 보는 것이다.
String aiMessageFor(ApiFailure failure) => switch (failure) {
  // 오프라인은 오류가 아니라 정상 경로다.
  ApiFailure.network => '연결이 없어 요약하지 못했습니다.',
  ApiFailure.badRequest => '한 번에 200개까지 요약할 수 있습니다.',
  ApiFailure.notFound => '요약할 대화를 찾지 못했습니다.',
  ApiFailure.unauthorized => '다시 로그인해 주세요.',
  ApiFailure.tooLarge => '요약하기에 너무 큽니다.',
  ApiFailure.server => 'AI 를 쓸 수 없습니다. 잠시 뒤 다시 시도해 주세요.',
};

sealed class AiSummaryState {
  const AiSummaryState();
}

class AiIdle extends AiSummaryState {
  const AiIdle();
}

class AiRunning extends AiSummaryState {
  const AiRunning(this.runId);
  final String runId;
}

class AiReady extends AiSummaryState {
  const AiReady(this.run);
  final AiRun run;
}

class AiFailed extends AiSummaryState {
  const AiFailed(this.failure);
  final ApiFailure failure;
}

/// 요약 실행 상태.
///
/// **drift 에 넣지 않는다.** 「화면은 drift 만 구독한다」의 예외이고, 근거는
/// 8-2 의 `attachment_draft.dart` 선례다 — AI 결과는 오프라인에서 만들 수
/// 없고 일회성이라 캐시할 것이 없다 (설계 §11).
class AiSummaryController extends Notifier<AiSummaryState> {
  @override
  AiSummaryState build() {
    // 소켓이 완료를 알리면 결과를 가져온다. 놓쳐도 화면의 「다시 확인」이
    // 같은 GET 을 부른다 — 두 경로가 하나다.
    ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (_, next) {
      final event = next.value;
      if (event is! AiRunDone) return;
      final current = state;
      if (current is! AiRunning || current.runId != event.runId) return;
      unawaited(_fetch(event.runId));
    });
    return const AiIdle();
  }

  Future<void> run({
    required String spaceId,
    required String channelId,
    required List<String> messageIds,
  }) async {
    _spaceId = spaceId;
    state = const AiRunning('');
    try {
      final runId = await ref
          .read(aiApiProvider)
          .summarize(
            spaceId: spaceId,
            channelId: channelId,
            messageIds: messageIds,
          );
      state = AiRunning(runId);
      // **캐시 적중이면 소켓이 오지 않는다** — 이미 done 이다. 한 번 읽어
      // 확인한다. 두 경로가 같은 GET 을 쓰는 이유가 이것이다.
      await _fetch(runId);
    } on ApiException catch (err) {
      // AiApi 가 DioException 을 ApiException 으로 감싸 던진다(Task 11).
      state = AiFailed(err.failure);
    }
  }

  /// **결과를 기다리지 않는다.** 서버의 호출을 끊지는 못한다 — 끊을 수 있는
  /// 척하지 않는다 (판단 #7).
  void abandon() => state = const AiIdle();

  String _spaceId = '';

  Future<void> _fetch(String runId) async {
    try {
      final run = await ref.read(aiApiProvider).getRun(_spaceId, runId);
      if (run.state == AiRunState.done) {
        state = AiReady(run);
      } else if (run.state == AiRunState.failed) {
        state = const AiFailed(ApiFailure.server);
      }
      // queued · running 이면 그대로 기다린다.
    } on ApiException catch (err) {
      // AiApi 가 DioException 을 ApiException 으로 감싸 던진다(Task 11).
      state = AiFailed(err.failure);
    }
  }
}

final aiSummaryControllerProvider =
    NotifierProvider<AiSummaryController, AiSummaryState>(
      AiSummaryController.new,
    );
