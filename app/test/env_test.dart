import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/core/env.dart';

/// API 주소를 만드는 유일한 지점(`core/env.dart`)의 불변식.
///
/// 서버가 모든 라우트를 `/api` 아래에 두므로(server/src/main.ts 의 setGlobalPrefix)
/// 여기가 어긋나면 앱 전체가 404 다. (옛 이름 widget_test.dart — `flutter create` 의
/// 카운터 테스트 자리를 물려받아 이름만 남아 있었다.)
void main() {
  test('apiRoot 는 API_BASE 뒤에 /api 를 붙인다', () {
    expect(Env.apiRoot, equals('${Env.apiBase}/api'));
    expect(Env.apiRoot, endsWith('/api'));
  });

  test('기본 API_BASE 는 스킴을 갖는다', () {
    expect(Uri.parse(Env.apiBase).hasScheme, isTrue);
  });
}
