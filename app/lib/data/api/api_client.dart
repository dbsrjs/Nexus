import 'package:dio/dio.dart';

import '../../core/env.dart';
import '../../domain/models/auth_tokens.dart';
import '../auth_storage.dart';

/// dio 클라이언트와 토큰 수명 관리.
///
/// 액세스 토큰은 메모리에, 영속은 [AuthStorage] 에 둔다. 매 요청마다 안전
/// 저장소를 읽으면 느리고, 메모리에만 두면 재시작 시 사라진다.
///
/// 401 을 받으면 **리프레시를 한 번만** 시도한다. 무한 재시도는 서버의
/// 리프레시 재사용 탐지에 걸려 그 세션 family 전체가 끊긴다
/// (server/src/auth/refresh-token.service.ts).
class ApiClient {
  ApiClient({required AuthStorage storage}) : _storage = storage {
    dio = Dio(_baseOptions);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokens?.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: _onError,
      ),
    );
  }

  final AuthStorage _storage;

  late final Dio dio;

  /// 리프레시 전용. 인터셉터가 없어서 재귀하지 않는다.
  late final Dio _refreshDio = Dio(_baseOptions);

  AuthTokens? _tokens;

  /// 리프레시까지 실패했을 때 호출된다. 라우터가 로그인 화면으로 보내는 데 쓴다.
  void Function()? onSessionExpired;

  static BaseOptions get _baseOptions => BaseOptions(
        baseUrl: Env.apiRoot,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        // 4xx 를 예외로 받는다. 상태 코드 분기는 호출부에서 한다.
        validateStatus: (status) => status != null && status < 400,
      );

  bool get hasTokens => _tokens != null;

  /// 앱 시작 시 한 번. 저장소의 토큰을 메모리로 올린다.
  Future<void> restore() async {
    _tokens = await _storage.read();
  }

  Future<void> setTokens(AuthTokens tokens) async {
    // 리프레시 응답에는 refreshToken 이 없을 수 있다(웹 경로). 그때 기존 값을
    // 버리지 않도록 병합한다.
    _tokens = AuthTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken ?? _tokens?.refreshToken,
    );
    await _storage.write(_tokens!);
  }

  Future<void> clearTokens() async {
    _tokens = null;
    await _storage.clear();
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final response = error.response;
    final request = error.requestOptions;

    final isUnauthorized = response?.statusCode == 401;
    final alreadyRetried = request.extra['nexus.retried'] == true;
    final refreshToken = _tokens?.refreshToken;

    // 리프레시 요청 자체가 401 이면 되살릴 방법이 없다.
    final isRefreshCall = request.path == '/auth/refresh';

    if (!isUnauthorized ||
        alreadyRetried ||
        isRefreshCall ||
        refreshToken == null) {
      handler.next(error);
      return;
    }

    try {
      final refreshed = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken, 'client': 'native'},
      );
      await setTokens(AuthTokens.fromJson(refreshed.data!));
    } catch (_) {
      // 만료됐거나 재사용으로 끊긴 토큰이다. 흔적을 지우고 세션 종료를 알린다.
      await clearTokens();
      onSessionExpired?.call();
      handler.next(error);
      return;
    }

    try {
      // 원 요청을 새 토큰으로 한 번만 재시도한다.
      final retried = await dio.fetch<dynamic>(
        request
          ..headers['Authorization'] = 'Bearer ${_tokens!.accessToken}'
          ..extra['nexus.retried'] = true,
      );
      handler.resolve(retried);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
