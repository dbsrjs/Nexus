import 'package:dio/dio.dart';

/// 요청 실패의 종류.
///
/// `AuthFailure`(auth_api.dart)와 같은 이유로 존재한다 — **서버 메시지를 화면에
/// 그대로 쓰지 않기 위해서다.** 서버는 한국어 문구를 주지만 앱이 그것을 신뢰하면
/// 서버 문구가 바뀔 때마다 앱 UX 가 흔들린다. 앱은 종류만 받아 자기 문구를 쓴다.
enum ApiFailure {
  /// 토큰이 없거나 만료됐다 (401). 인터셉터의 리프레시까지 실패한 경우다.
  unauthorized,

  /// 없거나, 볼 권한이 없다. 서버는 남의 테넌트에 대해 403 이 아니라 404 를 준다
  /// (docs/백엔드-설계.md §2) — 존재 여부 자체를 숨기기 위함이다.
  notFound,

  /// 서버에 닿지 못했다 — 꺼져 있거나 주소가 틀렸다.
  network,

  /// 파일이 서버 한도를 넘었다 (413). 재시도해도 같으므로 다른 문구가 필요하다.
  tooLarge,

  /// 그 밖의 서버 오류.
  server,
}

class ApiException implements Exception {
  const ApiException(this.failure);

  final ApiFailure failure;

  @override
  String toString() => 'ApiException($failure)';
}

/// DioException 을 실패 종류로 옮긴다.
ApiFailure classifyDioException(DioException e) {
  switch (e.response?.statusCode) {
    case 401:
      return ApiFailure.unauthorized;
    case 403:
    case 404:
      return ApiFailure.notFound;
    case 413:
      return ApiFailure.tooLarge;
  }

  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return ApiFailure.network;
    default:
      return ApiFailure.server;
  }
}

/// 실패 종류를 사람이 읽을 문구로. 화면마다 다시 쓰지 않도록 한곳에 둔다.
String messageFor(ApiFailure failure) => switch (failure) {
      ApiFailure.unauthorized => '다시 로그인해 주세요.',
      ApiFailure.notFound => '찾을 수 없습니다.',
      ApiFailure.network => '서버에 연결할 수 없습니다.',
      ApiFailure.tooLarge => '파일이 너무 큽니다.',
      ApiFailure.server => '문제가 생겼습니다. 잠시 후 다시 시도해 주세요.',
    };
