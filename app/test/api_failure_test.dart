import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/api_failure.dart';

/// 실패 분류(api_failure.dart).
///
/// 2026-10-06 리팩토링에서 API 파일 59곳의 `try/on DioException` 이 `guardApi` 하나로
/// 모였다. 바꾸는 규칙이 한곳이 된 대신, **여기가 틀리면 앱 전체의 오류 문구가 함께
/// 틀린다** — 진짜 500 에 «GitHub 을 연결하세요» 가 뜨던 것(400 · 500 을 하나로 접음)이
/// 그 모양이었다.
void main() {
  DioException withStatus(int status) {
    final request = RequestOptions(path: '/x');
    return DioException(
      requestOptions: request,
      response: Response<void>(requestOptions: request, statusCode: status),
      type: DioExceptionType.badResponse,
    );
  }

  DioException withType(DioExceptionType type) => DioException(
    requestOptions: RequestOptions(path: '/x'),
    type: type,
  );

  group('classifyDioException', () {
    test('상태 코드가 종류를 정한다', () {
      expect(classifyDioException(withStatus(401)), ApiFailure.unauthorized);
      expect(classifyDioException(withStatus(404)), ApiFailure.notFound);
      expect(classifyDioException(withStatus(413)), ApiFailure.tooLarge);
      expect(classifyDioException(withStatus(500)), ApiFailure.server);
    });

    test('★ 400 은 server 와 갈린다 - 사용자가 할 일이 다르다', () {
      expect(classifyDioException(withStatus(400)), ApiFailure.badRequest);
      expect(classifyDioException(withStatus(503)), ApiFailure.server);
    });

    test('403 도 notFound 다 - 서버는 남의 것의 존재를 알리지 않는다', () {
      expect(classifyDioException(withStatus(403)), ApiFailure.notFound);
    });

    test('응답이 없으면 연결 실패 종류를 본다', () {
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      ]) {
        expect(
          classifyDioException(withType(type)),
          ApiFailure.network,
          reason: '$type',
        );
      }
      expect(
        classifyDioException(withType(DioExceptionType.unknown)),
        ApiFailure.server,
      );
    });
  });

  group('guardApi', () {
    test('Dio 실패를 ApiException 으로 바꾼다', () async {
      await expectLater(
        guardApi<void>(() async => throw withStatus(404)),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            ApiFailure.notFound,
          ),
        ),
      );
    });

    test('Dio 가 아닌 예외는 감추지 않고 그대로 던진다', () async {
      await expectLater(
        guardApi<void>(() async => throw const FormatException('파싱')),
        throwsA(isA<FormatException>()),
      );
    });

    test('성공하면 값을 그대로 돌려준다', () async {
      expect(await guardApi(() async => 7), 7);
    });
  });

  test('★ ApiException 이 아닌 실패는 서버 문구를 쓰지 않고 일반 문구가 된다', () {
    expect(
      messageForError(const ApiException(ApiFailure.notFound)),
      messageFor(ApiFailure.notFound),
    );
    expect(
      messageForError(Exception('서버가 준 원문')),
      messageFor(ApiFailure.server),
    );
    expect(messageForError(null), messageFor(ApiFailure.server));
  });
}
