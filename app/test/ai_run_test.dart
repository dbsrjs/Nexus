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

    test('모르는 state 는 queued 로 떨어진다 — 앱이 죽지 않는다', () {
      final run = AiRun.fromJson(const {
        'runId': 'r-1',
        'kind': 'summarize',
        'state': 'cancelling',
      });
      expect(run.state, AiRunState.queued);
    });
  });
}
