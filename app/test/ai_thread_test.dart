import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/ai_run.dart';
import 'package:nexus_app/domain/models/ai_thread.dart';
import 'package:nexus_app/features/ai/ai_request.dart';

void main() {
  group('AiThreadPage.fromJson', () {
    final page = AiThreadPage.fromJson({
      'items': [
        {
          'rootRunId': 'r1',
          'kind': 'ask',
          'question': '버그가 어디야?',
          'preset': null,
          'turnCount': 2,
          'lastAt': '2026-10-07T10:13:16.301Z',
          'preview': '## 답\n본문',
          'context': {'channelId': 'c1', 'messageCount': 3, 'repoId': 'p1'},
        },
        {
          'rootRunId': 'r2',
          'kind': 'summarize',
          'question': null,
          'preset': 'summary',
          'turnCount': 1,
          'lastAt': '2026-10-07T09:00:00.000Z',
          'preview': '',
          'context': {'channelId': null, 'messageCount': null, 'repoId': null},
        },
      ],
      'nextCursor': 'r2',
    });

    test('항목 칸과 다음 커서', () {
      final first = page.items.first;
      expect(first.rootRunId, 'r1');
      expect(first.turnCount, 2);
      expect(first.lastAt, DateTime.utc(2026, 10, 7, 10, 13, 16, 301));
      expect(first.channelId, 'c1');
      expect(first.messageCount, 3);
      expect(first.repoId, 'p1');
      expect(page.nextCursor, 'r2');
    });

    test('제목은 질문, 없으면 프리셋 이름', () {
      expect(page.items[0].title, '버그가 어디야?');
      expect(page.items[1].title, '요약');
      expect(page.items[1].channelId, isNull);
    });

    test('끝이면 커서는 null', () {
      expect(
        AiThreadPage.fromJson({'items': [], 'nextCursor': null}).nextCursor,
        isNull,
      );
    });
  });

  group('AiThread.fromJson', () {
    final thread = AiThread.fromJson({
      'rootRunId': 'r1',
      'context': {
        'channelId': 'c1',
        'messageIds': ['m1', 'm2'],
        'repoId': null,
      },
      'turns': [
        {
          'runId': 'r1',
          'kind': 'summarize',
          'state': 'done',
          'result': {'markdown': '요약 답'},
          'instruction': null,
          'preset': 'summary',
        },
        {
          'runId': 'r2',
          'kind': 'ask',
          'state': 'done',
          'result': {'markdown': '이어진 답'},
          'parentRunId': 'r1',
          'instruction': '담당자별로',
          'preset': null,
        },
      ],
    });

    test('근거와 턴을 뿌리부터 읽는다', () {
      expect(thread.channelId, 'c1');
      expect(thread.messageIds, ['m1', 'm2']);
      expect(thread.repoId, isNull);
      expect(thread.turns.map((t) => t.run.runId), ['r1', 'r2']);
      expect(thread.turns[1].run.markdown, '이어진 답');
      expect(thread.turns[1].run.state, AiRunState.done);
    });

    test('턴의 질문 — 프리셋은 이름, 지시문은 그대로', () {
      expect(thread.turns[0].question, '요약');
      expect(thread.turns[1].question, '담당자별로');
    });
  });

  test('모르는 프리셋 문자열은 null 이다', () {
    expect(aiPresetOf('summary'), AiPreset.summary);
    expect(aiPresetOf('issue'), AiPreset.issue);
    expect(aiPresetOf('translate'), isNull);
    expect(aiPresetOf(null), isNull);
  });
}
