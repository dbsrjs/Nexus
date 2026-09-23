import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/core/theme.dart';
import 'package:nexus_app/data/api/ai_api.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/domain/models/ai_run.dart';
import 'package:nexus_app/features/ai/ai_controller.dart';
import 'package:nexus_app/features/ai/ai_panel.dart';
import 'package:nexus_app/features/ai/ai_request.dart';
import 'package:nexus_app/features/realtime/socket_controller.dart';

const _messages = MessagesContext(channelId: 'c1', messageIds: ['m1', 'm2']);
const _repo = RepoContext(repoId: 'r1', repoName: 'nexus');

class _FakeAiApi implements AiApi {
  AiRun result = const AiRun(
    runId: 'run-1',
    kind: 'ask',
    state: AiRunState.done,
    markdown: '답',
  );
  ApiFailure? failWith;
  final List<AiRequest> asked = [];

  @override
  Future<String> ask(String spaceId, AiRequest request) async {
    asked.add(request);
    if (failWith != null) throw ApiException(failWith!);
    return 'run-1';
  }

  @override
  Future<AiRun> getRun(String spaceId, String runId) async => result;
}

Future<_FakeAiApi> _pump(
  WidgetTester tester, {
  required List<AiContext> contexts,
  CreateIssueFromDraft? onCreateIssue,
  Future<void> Function(String)? onPost,
}) async {
  final api = _FakeAiApi();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aiApiProvider.overrideWithValue(api),
        socketEventsProvider.overrideWith((ref) => const Stream.empty()),
      ],
      child: MaterialApp(
        theme: buildNexusTheme(brightness: Brightness.dark),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AiPanel(
              spaceId: 's1',
              initialContexts: contexts,
              onCreateIssue: onCreateIssue,
              onPost: onPost,
            ),
          ),
        ),
      ),
    ),
  );
  return api;
}

FilledButton _sendButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.ancestor(
    of: find.text('보내기'),
    matching: find.byWidgetPredicate((w) => w is FilledButton),
  ),
);

OutlinedButton _outlined(WidgetTester tester, String label) =>
    tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton),
      ),
    );

void main() {
  testWidgets('★ 마지막 칩을 지우면 보내기가 꺼진다 - 근거 없는 질문은 받지 않는다', (tester) async {
    await _pump(tester, contexts: const [_messages]);
    await tester.enterText(find.byType(TextField), '뭐 정했어?');
    await tester.pump();
    expect(_sendButton(tester).onPressed, isNotNull);

    await tester.tap(find.byTooltip('빼기'));
    await tester.pump();

    expect(find.text('메시지 2개'), findsNothing);
    expect(_sendButton(tester).onPressed, isNull);
  });

  testWidgets('★ 대화 칩이 없으면 프리셋이 꺼진다 - 코드만으로 요약하지 않는다', (tester) async {
    await _pump(
      tester,
      contexts: const [_repo],
      onCreateIssue:
          ({required title, required description, originMessageId}) {},
    );
    expect(_outlined(tester, '요약').onPressed, isNull);
    expect(_outlined(tester, '이슈로 만들기').onPressed, isNull);
  });

  testWidgets('지시문을 보내면 칩이 그대로 요청에 실린다', (tester) async {
    final api = await _pump(tester, contexts: const [_messages, _repo]);
    await tester.enterText(find.byType(TextField), '  버그가 어디야? ');
    await tester.pump();
    await tester.tap(find.text('보내기'));
    await tester.pumpAndSettle();

    expect(api.asked.single.instruction, '버그가 어디야?');
    expect(api.asked.single.hasRepo, isTrue);
    expect(api.asked.single.hasConversation, isTrue);
  });

  testWidgets('★ 결과에 참고한 코드가 [n] 경로:줄 로 보인다', (tester) async {
    final api = await _pump(tester, contexts: const [_repo]);
    api.result = const AiRun(
      runId: 'run-1',
      kind: 'ask',
      state: AiRunState.done,
      markdown: '[1] 에서 다시 붙는다',
      citations: [
        AiCitation(
          n: 1,
          path: 'lib/socket.dart',
          startLine: 1,
          endLine: 6,
          commitSha: 'abc',
        ),
      ],
    );
    await tester.enterText(find.byType(TextField), '재연결은 어디서?');
    await tester.pump();
    await tester.tap(find.text('보내기'));
    await tester.pumpAndSettle();

    expect(find.text('참고한 코드'), findsOneWidget);
    expect(find.text('lib/socket.dart:1-6'), findsOneWidget);
    // 채널 밖에서 열었으므로 붙일 채널이 없다.
    expect(find.text('채널에 붙이기'), findsNothing);
  });

  testWidgets('★ 전환 모델이 답했으면 결과에 한 줄로 알린다 - 품질이 조용히 떨어지지 않게', (tester) async {
    final api = await _pump(tester, contexts: const [_messages]);
    api.result = const AiRun(
      runId: 'run-1',
      kind: 'ask',
      state: AiRunState.done,
      markdown: '답',
      fallback: true,
    );
    await tester.enterText(find.byType(TextField), '정리해 줘');
    await tester.pump();
    await tester.tap(find.text('보내기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('가벼운 모델'), findsOneWidget);
  });

  testWidgets('주 모델이 답했으면 그 줄이 없다', (tester) async {
    await _pump(tester, contexts: const [_messages]);
    await tester.enterText(find.byType(TextField), '정리해 줘');
    await tester.pump();
    await tester.tap(find.text('보내기'));
    await tester.pumpAndSettle();

    expect(find.text('답'), findsOneWidget);
    expect(find.textContaining('가벼운 모델'), findsNothing);
  });

  testWidgets('★ 이슈 초안 결과에서 「이슈 만들기」가 제목 · 본문 · 첫 메시지를 넘긴다', (tester) async {
    Map<String, String?>? handed;
    final api = await _pump(
      tester,
      contexts: const [_messages],
      onCreateIssue:
          ({required title, required description, originMessageId}) =>
              handed = {
                'title': title,
                'description': description,
                'origin': originMessageId,
              },
    );
    api.result = const AiRun(
      runId: 'run-1',
      kind: 'draft_issue',
      state: AiRunState.done,
      title: '로그인 버튼 고치기',
      description: '눌리지 않는다',
    );
    await tester.tap(find.text('이슈로 만들기'));
    await tester.pumpAndSettle();

    expect(api.asked.single.preset, AiPreset.issue);
    expect(find.text('로그인 버튼 고치기'), findsOneWidget);
    await tester.tap(find.text('이슈 만들기'));
    await tester.pumpAndSettle();

    expect(handed, {
      'title': '로그인 버튼 고치기',
      'description': '눌리지 않는다',
      'origin': 'm1',
    });
  });

  testWidgets('★ 실패 문구는 앱의 것이고, 저장소가 있으면 인덱싱을 가리킨다', (tester) async {
    final api = await _pump(tester, contexts: const [_repo]);
    api.failWith = ApiFailure.server;
    await tester.enterText(find.byType(TextField), 'q');
    await tester.pump();
    await tester.tap(find.text('보내기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('인덱싱'), findsOneWidget);

    // 「다시 묻기」는 같은 칩으로 입력 화면에 돌아간다.
    await tester.tap(find.text('다시 묻기'));
    await tester.pumpAndSettle();
    expect(find.text('nexus'), findsOneWidget);
    expect(find.text('보내기'), findsOneWidget);
  });
}
