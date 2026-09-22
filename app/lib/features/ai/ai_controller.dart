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
  /// **세대 토큰.** `run()` · `abandon()` 이 호출될 때마다 하나 늘어난다.
  ///
  /// `await` 뒤에서 `state =` 로 대입하기 전에 항상 "내가 부를 때의 세대가
  /// 지금도 최신인가"를 확인한다 — 아니면 조용히 버린다. 이것이 없으면 둘이
  /// 어긋난다: ① `run()` 이 응답을 기다리는 동안 `abandon()` 을 부르면, 늦게
  /// 도착한 응답이 `AiIdle` 을 무조건 `AiRunning` 으로 되돌린다. ② `run()` 을
  /// 빠르게 두 번 부르면 두 번째 호출이 먼저 다음 필드를 덮어써, 첫 번째
  /// 호출의 뒤이은 `_fetch` 가 **엉뚱한 스페이스**로 조회한다(테넌트 격리에
  /// 걸려 404 — 원인과 다른 문구가 뜬다). `_fetch` 가 `spaceId` 를 필드가
  /// 아니라 **인자로** 받는 것도 같은 이유다 — 호출자(자기 세대)가 붙잡고
  /// 있는 값을 쓰면 다른 세대가 필드를 덮어써도 영향받지 않는다.
  int _generation = 0;

  /// 소켓이 완료를 알렸을 때 조회할 스페이스. **`run()` 시작 시점에만 쓰고
  /// 그 뒤로는 건드리지 않는다** — `state` 가 `AiRunning(runId)` 로 남아
  /// 있는 동안은 그 값을 세운 세대가 아직 살아 있다는 뜻이므로(다른 세대가
  /// 시작됐다면 `state` 부터 먼저 덮어썼을 것이다) 안전하다.
  String _activeSpaceId = '';

  @override
  AiSummaryState build() {
    // 소켓이 완료를 알리면 결과를 가져온다. 놓쳐도 화면의 「다시 확인」
    // (아래 retry())이 같은 GET 을 부른다 — 두 경로가 하나다.
    ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (_, next) {
      final event = next.value;
      if (event is! AiRunDone) return;
      final current = state;
      if (current is! AiRunning || current.runId != event.runId) return;
      unawaited(_fetch(_activeSpaceId, event.runId, _generation));
    });
    return const AiIdle();
  }

  Future<void> run({
    required String spaceId,
    required String channelId,
    required List<String> messageIds,
  }) async {
    final generation = ++_generation;
    _activeSpaceId = spaceId;
    state = const AiRunning('');
    try {
      final runId = await ref
          .read(aiApiProvider)
          .summarize(
            spaceId: spaceId,
            channelId: channelId,
            messageIds: messageIds,
          );
      // 기다리는 동안 abandon() 됐거나 다음 run() 이 시작됐으면 버린다 —
      // 이미 지나간 세대의 결과로 지금 세대(또는 AiIdle)를 덮지 않는다.
      if (generation != _generation) return;
      state = AiRunning(runId);
      // **캐시 적중이면 소켓이 오지 않는다** — 이미 done 이다. 한 번 읽어
      // 확인한다. 두 경로가 같은 GET 을 쓰는 이유가 이것이다. `spaceId` 는
      // 필드가 아니라 이 호출이 쥐고 있는 값을 그대로 넘긴다.
      await _fetch(spaceId, runId, generation);
    } on ApiException catch (err) {
      if (generation != _generation) return;
      // AiApi 가 DioException 을 ApiException 으로 감싸 던진다(Task 11).
      state = AiFailed(err.failure);
    }
  }

  /// **결과를 기다리지 않는다.** 서버의 호출을 끊지는 못한다 — 끊을 수 있는
  /// 척하지 않는다 (판단 #7). 세대를 올려 진행 중이던 `run()`/`_fetch` 가
  /// 나중에 응답을 받아도 이 상태를 덮지 못하게 한다.
  void abandon() {
    _generation++;
    state = const AiIdle();
  }

  /// 소켓 이벤트를 놓쳤을 때 화면의 「다시 확인」이 부른다. `run()` 이 캐시
  /// 적중을 확인할 때 쓰는 것과 **같은 GET** 이다 — `build()` 의 주석이
  /// 약속한 두 경로가 실제로 하나가 되는 지점이다(최종 whole-branch 리뷰
  /// Important ④: 이 메서드가 없어 소켓을 놓치면 스피너가 영원히 돌았다).
  ///
  /// `AiRunning` 일 때만 의미가 있다 — 그 밖의 상태에서 눌릴 버튼은 화면에
  /// 없다(판단 #7). `runId` 가 아직 빈 문자열이면(`run()` 이 `summarize()`
  /// 응답을 기다리는 중) 할 것이 없다.
  Future<void> retry() async {
    final current = state;
    if (current is! AiRunning || current.runId.isEmpty) return;
    await _fetch(_activeSpaceId, current.runId, _generation);
  }

  Future<void> _fetch(String spaceId, String runId, int generation) async {
    try {
      final run = await ref.read(aiApiProvider).getRun(spaceId, runId);
      if (generation != _generation) return;
      if (run.state == AiRunState.done) {
        state = AiReady(run);
      } else if (run.state == AiRunState.failed) {
        state = const AiFailed(ApiFailure.server);
      }
      // queued · running 이면 그대로 기다린다.
    } on ApiException catch (err) {
      if (generation != _generation) return;
      // AiApi 가 DioException 을 ApiException 으로 감싸 던진다(Task 11).
      state = AiFailed(err.failure);
    }
  }
}

final aiSummaryControllerProvider =
    NotifierProvider<AiSummaryController, AiSummaryState>(
      AiSummaryController.new,
    );
