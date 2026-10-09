import '../features/auth/auth_controller.dart';

/// 인증 상태에 따라 어디로 보낼지(라우터의 `redirect`). **가려던 주소를 잃지 않는 것**이 핵심이다.
///
/// 예전에는 토큰을 확인하는 동안 무조건 `/` 로 보냈다가 로그인이 확인되면 `/spaces` 로 보냈다 —
/// 웹에서 새로고침하면 늘 스페이스 고르기로 돌아갔고(진행 기록 «웹 확인»), 초대 링크를 눌러도
/// 로그인 뒤에는 링크가 사라졌다. 이제 거쳐 가는 화면(`/` · `/login`)이 `from` 으로 원래 주소를
/// 들고 다니다가 로그인이 확인되는 순간 돌려준다.
///
/// 라우터와 떼어 둔 이유는 테스트다 — go_router 를 띄우지 않고 갈래마다 확인한다.
String? authRedirect(AuthState auth, Uri location) {
  final path = location.path.isEmpty ? '/' : location.path;
  final carried = location.queryParameters['from'];

  // 지금 주소가 곧 가려던 곳이다. 거쳐 가는 화면에 있으면 그 화면이 들고 있던 것을 넘긴다.
  final wanted = _isWaypoint(path) ? carried : location.toString();

  if (auth is AuthRestoring) {
    // 여기서 /login 으로 보내면 앱을 켤 때마다 로그인 화면이 깜빡인다.
    return path == '/' ? null : _withFrom('/', wanted);
  }

  final onAuthPage = path == '/login' || path == '/signup';
  if (auth is! AuthSignedIn) {
    if (onAuthPage) return null;
    // 스스로 나온 것이면 보던 곳을 들고 가지 않는다(AuthSignedOut.byUser).
    if (auth is AuthSignedOut && auth.byUser) return '/login';
    return _withFrom('/login', wanted);
  }

  if (onAuthPage || path == '/') return safeReturnPath(carried) ?? '/spaces';
  return null;
}

bool _isWaypoint(String path) =>
    path == '/' || path == '/login' || path == '/signup';

String _withFrom(String path, String? from) {
  final safe = safeReturnPath(from);
  if (safe == null) return path;
  return Uri(path: path, queryParameters: {'from': safe}).toString();
}

/// `from` 으로 받은 값이 이 앱 안의 주소인지. **바깥 주소로 튕기는 데 쓰이지 않게** 한다 —
/// 링크에 `from=//evil.example` 을 넣어 로그인 직후 남의 사이트로 보내는 고전적인 수법이다.
/// 거쳐 가는 화면으로 돌아가는 것도 막는다(되돌이 고리).
String? safeReturnPath(String? from) {
  if (from == null || from.isEmpty) return null;
  if (!from.startsWith('/') || from.startsWith('//') || from.contains('\\')) {
    return null;
  }
  final parsed = Uri.tryParse(from);
  if (parsed == null || parsed.hasScheme || parsed.hasAuthority) return null;
  if (_isWaypoint(parsed.path)) return null;
  return from;
}
