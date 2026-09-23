import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/ai_run.dart';

void main() {
  group('AiRun.fromJson', () {
    test('done 이면 markdown 을 읽는다', () {
      final run = AiRun.fromJson(const {
        'runId': 'r-1',
        'kind': 'summarize',
        'state': 'done',
        'result': {'markdown': '# 요약'},
      });
      expect(run.state, AiRunState.done);
      expect(run.markdown, '# 요약');
    });

    test('queued 면 markdown 이 null 이다 — 빈 문자열로 지어내지 않는다', () {
      final run = AiRun.fromJson(const {
        'runId': 'r-1',
        'kind': 'summarize',
        'state': 'queued',
        'result': null,
      });
      expect(run.state, AiRunState.queued);
      expect(run.markdown, isNull);
    });

    test('failed 면 error 를 읽는다', () {
      final run = AiRun.fromJson(const {
        'runId': 'r-1',
        'kind': 'summarize',
        'state': 'failed',
        'error': '모델이 답하지 않았습니다',
      });
      expect(run.state, AiRunState.failed);
      expect(run.error, isNotNull);
    });

    test('★ fallback 을 읽는다 - 전환 모델이 답했는지. 없으면 false', () {
      final fb = AiRun.fromJson(const {
        'runId': 'r-1',
        'kind': 'summarize',
        'state': 'done',
        'fallback': true,
        'result': {'markdown': '요약'},
      });
      final plain = AiRun.fromJson(const {
        'runId': 'r-1',
        'kind': 'summarize',
        'state': 'done',
        'result': {'markdown': '요약'},
      });
      expect(fb.fallback, isTrue);
      expect(plain.fallback, isFalse);
    });

    test('모르는 state 는 queued 로 떨어진다 — 앱이 죽지 않는다', () {
      final run = AiRun.fromJson(const {
        'runId': 'r-1',
        'kind': 'summarize',
        'state': 'cancelling',
      });
      expect(run.state, AiRunState.queued);
    });

    test('★ 인용을 읽는다 - 서버가 검색 결과에서 채운 것이다', () {
      final run = AiRun.fromJson(const {
        'runId': 'r-1',
        'kind': 'ask',
        'state': 'done',
        'result': {
          'markdown': '[1] 에 있다',
          'citations': [
            {'n': 1, 'path': 'lib/a.dart', 'startLine': 3, 'endLine': 9, 'commitSha': 'abc'},
          ],
        },
      });
      expect(run.citations, hasLength(1));
      expect(run.citations.single.location, 'lib/a.dart:3-9');
      expect(run.citations.single.commitSha, 'abc');
    });

    test('이슈 초안은 제목 · 본문을 읽는다', () {
      final run = AiRun.fromJson(const {
        'runId': 'r-1',
        'kind': 'draft_issue',
        'state': 'done',
        'result': {'title': '버튼 고침', 'description': '본문', 'citations': []},
      });
      expect(run.isIssueDraft, isTrue);
      expect(run.title, '버튼 고침');
      expect(run.description, '본문');
      expect(run.markdown, isNull);
    });

    test('인용이 없으면 빈 목록이다', () {
      final run = AiRun.fromJson(const {'runId': 'r-1', 'state': 'queued'});
      expect(run.citations, isEmpty);
    });
  });
}
