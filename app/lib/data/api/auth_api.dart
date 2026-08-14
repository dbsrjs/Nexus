import 'package:dio/dio.dart';

import '../../domain/models/auth_tokens.dart';
import '../../domain/models/user.dart';
import 'api_client.dart';

/// 인증 실패의 종류. 서버 메시지를 그대로 화면에 쓰지 않기 위한 구분이다.
///
/// 서버는 한국어 메시지를 주지만, 앱이 그것을 신뢰하면 서버 문구가 바뀔 때마다
/// 앱 UX 가 흔들린다. 앱은 종류만 받아 자기 문구를 쓴다.
enum AuthFailure {
  /// 이메일 또는 비밀번호가 틀렸다 (401).
  invalidCredentials,

  /// 서버에 닿지 못했다 — 꺼져 있거나 주소가 틀렸다.
  network,

  /// 그 밖의 서버 오류 (5xx 등).
  server,
}

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException($failure)';
}

class LoginResult {
  const LoginResult({required this.user, required this.tokens});

  final User user;
  final AuthTokens tokens;
}

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// POST /api/auth/login
  ///
  /// `client: 'native'` 를 명시한다. 서버는 `web` 일 때만 리프레시 토큰을
  /// 쿠키로 돌리고 바디에서 뺀다. 기본값도 native 지만, 명시해 두면 웹 분기를
  /// 붙일 때 어디를 바꿔야 하는지 드러난다.
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password, 'client': 'native'},
      );
      final body = res.data!;
      return LoginResult(
        user: User.fromJson(body['user'] as Map<String, dynamic>),
        tokens: AuthTokens.fromJson(body),
      );
    } on DioException catch (e) {
      throw AuthException(_classify(e));
    }
  }

  /// GET /api/me — 저장된 토큰이 아직 쓸 수 있는지 확인하는 데도 쓴다.
  Future<User> me() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/me');
      return User.fromJson(res.data!);
    } on DioException catch (e) {
      throw AuthException(_classify(e));
    }
  }

  /// POST /api/auth/logout — 이 세션의 리프레시 family 를 서버에서 끊는다.
  ///
  /// 서버 호출이 실패해도 로컬 토큰은 지운다. 사용자가 로그아웃을 눌렀는데
  /// 네트워크 때문에 로그인 상태로 남는 것이 더 나쁘다.
  Future<void> logout(String? refreshToken) async {
    if (refreshToken == null) return;
    try {
      await _client.dio.post<void>(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException {
      // 무시한다 — 호출부가 어차피 로컬 토큰을 지운다.
    }
  }

  AuthFailure _classify(DioException e) {
    if (e.response?.statusCode == 401) return AuthFailure.invalidCredentials;
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return AuthFailure.network;
      default:
        return AuthFailure.server;
    }
  }
}
