import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/core/env.dart';

/// 슬라이스 1 은 자동화된 테스트를 목표로 하지 않는다 — 화면이 하나뿐이라
/// 위젯 테스트로 얻는 것이 적고, 통합 테스트(로그인 → 채널 → 전송)는
/// 슬라이스 3 이 끝나야 의미가 있다 (docs/앱-설계.md §10).
///
/// 다만 `flutter create` 가 만든 기본 카운터 테스트는 지웠고, 그 자리에
/// 실제 불변식 하나를 남긴다. 서버가 모든 라우트를 `/api` 아래에 두므로
/// (server/src/main.ts 의 setGlobalPrefix) 여기가 어긋나면 앱 전체가 404 다.
void main() {
  test('apiRoot 는 API_BASE 뒤에 /api 를 붙인다', () {
    expect(Env.apiRoot, equals('${Env.apiBase}/api'));
    expect(Env.apiRoot, endsWith('/api'));
  });

  test('기본 API_BASE 는 스킴을 갖는다', () {
    expect(Uri.parse(Env.apiBase).hasScheme, isTrue);
  });
}
