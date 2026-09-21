import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/ai_api.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/domain/models/ai_run.dart';
import 'package:nexus_app/features/ai/ai_controller.dart';
import 'package:nexus_app/features/realtime/socket_controller.dart';

void main() {
  group('aiMessageFor', () {
    test('★ 종류마다 앱이 자기 문구를 쓴다 - 서버 문구를 그대로 쓰지 않는다', () {
      // `ApiFailure` 에 값이 하나 늘면 이 테스트가 먼저 깨진다 — 문구를
      // 빠뜨린 채 화면이 빈칸을 보이는 것을 막는다.
      for (final failure in ApiFailure.values) {
        expect(aiMessageFor(failure), isNotEmpty);
      }
    });

    test('★ 오프라인은 오류가 아니라 정상 경로다 - 문구가 달라야 한다', () {
      expect(
        aiMessageFor(ApiFailure.network),
        isNot(aiMessageFor(ApiFailure.server)),
      );
    });

    test('400 은 너무 많이 고른 것을 말한다', () {
      expect(aiMessageFor(ApiFailure.badRequest), contains('200'));
    });

    test('일반 문구를 그대로 쓰지 않는다 - 요약 맥락의 문구여야 한다', () {
      // `messageFor()` 의 「찾을 수 없습니다」는 이 화면에 맞지 않는다.
      expect(
        aiMessageFor(ApiFailure.notFound),
        isNot(messageFor(ApiFailure.notFound)),
      );
    });
  });

  group('AiSummaryController — 경합', () {
    late _FakeAiApi api;
    late ProviderContainer container;

    setUp(() {
      api = _FakeAiApi();
      container = ProviderContainer(
        overrides: [
          aiApiProvider.overrideWithValue(api),
          // 소켓은 이 그룹의 관심사가 아니다 — 실제로 붙으려 하면(개발 서버가
          // 없는 테스트 환경이라) 연결 오류만 낸다. 빈 스트림으로 막아 둔다.
          socketEventsProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);
    });

    AiSummaryController notifier() =>
        container.read(aiSummaryControllerProvider.notifier);
    AiSummaryState state() => container.read(aiSummaryControllerProvider);

    test(
      '★ summarize() 를 기다리는 동안 abandon() 하면 늦게 온 응답이 상태를 되살리지 않는다',
      () async {
        final run = notifier().run(
          spaceId: 's1',
          channelId: 'c1',
          messageIds: const ['m1'],
        );

        // run() 이 summarize() 의 첫 await 까지는 동기로 돈다 — 진행 중임을
        // 확인한다.
        expect(state(), isA<AiRunning>());

        // 사용자가 「기다리지 않기」를 눌렀다.
        notifier().abandon();
        expect(state(), isA<AiIdle>());

        // 그제서야 서버가 늦게 응답한다.
        api.summarizeCompleter.complete('run-1');
        await run;

        // abandon 이후이므로 AiRunning 으로 되살아나면 안 된다.
        expect(state(), isA<AiIdle>());
      },
    );

    test('★ 두 번째 run() 이 먼저 시작되면, 늦게 끝난 첫 번째 run() 은 두 번째의 '
        'spaceId 로 조회하지 않는다', () async {
      // 첫 번째 호출 — 다른 스페이스.
      final first = notifier().run(
        spaceId: 'space-first',
        channelId: 'c1',
        messageIds: const ['m1'],
      );

      // 아직 첫 번째가 끝나기 전에 두 번째를 시작한다(빠르게 두 번 누름을
      // 흉내 낸다). 두 번째는 곧바로 done 까지 간다.
      api.getRunResult = const AiRun(
        runId: 'run-2',
        kind: 'summarize',
        state: AiRunState.done,
        markdown: '두 번째 요약',
      );
      final secondCompleter = Completer<String>();
      api.summarizeCompleter = secondCompleter;
      final second = notifier().run(
        spaceId: 'space-second',
        channelId: 'c2',
        messageIds: const ['m2'],
      );
      secondCompleter.complete('run-2');
      await second;

      expect(state(), isA<AiReady>());
      expect(api.getRunCalls.last.spaceId, 'space-second');

      // 이제야 첫 번째의 summarize() 가 응답한다 — 이미 버려진 세대다.
      final firstCompleter = api.summarizeCompletersByCall.first;
      firstCompleter.complete('run-1');
      await first;

      // 두 번째가 채운 AiReady 를 덮지 않는다 — 특히 space-first 로
      // 조회하지 않는다(호출이 하나 더 늘지 않는다).
      expect(api.getRunCalls, hasLength(1));
      expect(state(), isA<AiReady>());
    });
  });
}

/// `summarize()` 응답 시점을 손으로 조절하기 위한 가짜.
///
/// `implements AiApi` — `attachment_test.dart` 의 `_FakeApi` 선례와 같은
/// 방식이다. `AiApi` 생성자가 `ApiClient` 를 요구하지만 `implements` 는
/// 그 생성자를 부르지 않는다.
class _FakeAiApi implements AiApi {
  Completer<String> summarizeCompleter = Completer<String>();
  final List<Completer<String>> summarizeCompletersByCall = [];

  AiRun getRunResult = const AiRun(
    runId: 'run-1',
    kind: 'summarize',
    state: AiRunState.done,
    markdown: '가짜 요약',
  );
  final List<({String spaceId, String runId})> getRunCalls = [];

  @override
  Future<String> summarize({
    required String spaceId,
    required String channelId,
    required List<String> messageIds,
  }) {
    summarizeCompletersByCall.add(summarizeCompleter);
    return summarizeCompleter.future;
  }

  @override
  Future<AiRun> getRun(String spaceId, String runId) async {
    getRunCalls.add((spaceId: spaceId, runId: runId));
    return getRunResult;
  }
}
