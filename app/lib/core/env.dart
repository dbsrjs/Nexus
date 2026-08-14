/// 빌드 타임 설정. **API 주소를 읽는 유일한 지점이다.**
///
/// 옛 구조는 `www/api.js` 에 `localhost:3000` 을 박아 두어 실기기에서 연결이
/// 되지 않았다 (docs/앱-설계.md §9). 여기 말고 다른 곳에서 주소를 만들지 않는다.
///
/// 주입:
///   flutter run --dart-define=API_BASE=http://127.0.0.1:3000
///
/// 기본값이 `127.0.0.1` 인 이유: 개발·검증 루프를 Windows 데스크톱에서 돌기
/// 때문이다. Android 에뮬레이터에서 호스트를 가리키려면 `10.0.2.2` 를 주입해야
/// 한다 — 에뮬레이터는 자기 자신이 `127.0.0.1` 이다.
class Env {
  const Env._();

  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://127.0.0.1:3000',
  );

  /// 서버는 모든 라우트를 `/api` 아래에 둔다 (main.ts 의 setGlobalPrefix).
  static String get apiRoot => '$apiBase/api';
}
