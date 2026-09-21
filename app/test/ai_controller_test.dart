import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/features/ai/ai_controller.dart';

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
}
