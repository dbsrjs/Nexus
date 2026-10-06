import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/api_client.dart';
import 'package:nexus_app/domain/models/auth_tokens.dart';

import 'support/fake_http.dart';

/// 401 → 리프레시 → 재시도 (api_client.dart).
///
/// 서버의 리프레시 재사용 탐지는 같은 리프레시 토큰이 두 번 오면 **세션 family
/// 를 통째로 끊는다**(server/src/auth/refresh-token.service.ts). 그래서 앱이
/// 지켜야 할 것이 셋이다 — 재시도는 한 번뿐, 리프레시는 동시에 하나, 실패하면
/// 흔적을 지우고 세션 종료를 알린다. 어느 하나가 깨져도 화면은 멀쩡해 보이다가
/// 실기기에서 「갑자기 로그아웃됨」으로만 드러난다.
void main() {
  test('★ 401 을 받으면 리프레시 후 새 토큰으로 한 번 다시 보낸다', () async {
    final http = FakeHttpAdapter((r) async {
      if (r.path == '/auth/refresh') {
        return (status: 200, body: {'accessToken': 'a2', 'refreshToken': 'r2'});
      }
      final auth = r.headers['Authorization'];
      return auth == 'Bearer a2'
          ? (status: 200, body: {'ok': true})
          : (status: 401, body: null);
    });
    final client = await fakeApiClient(http);

    final res = await client.dio.get<Map<String, dynamic>>('/me');

    expect(res.data, {'ok': true});
    expect(http.count('/me'), 2);
    expect(http.count('/auth/refresh'), 1);
    expect(client.accessToken, 'a2');
  });

  test('★ 재시도도 401 이면 다시 리프레시하지 않고 실패를 넘긴다 - 무한 재시도 금지', () async {
    final http = FakeHttpAdapter((r) async {
      if (r.path == '/auth/refresh') {
        return (status: 200, body: {'accessToken': 'a2', 'refreshToken': 'r2'});
      }
      return (status: 401, body: null);
    });
    final client = await fakeApiClient(http);

    await expectLater(
      client.dio.get<void>('/me'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(http.count('/me'), 2);
    expect(http.count('/auth/refresh'), 1);
  });

  test('★ 동시에 온 401 들은 리프레시를 하나만 보낸다 - 재사용 탐지에 걸리지 않게', () async {
    final release = Completer<void>();
    final http = FakeHttpAdapter((r) async {
      if (r.path == '/auth/refresh') {
        // 리프레시가 도는 동안 나머지 401 이 도착하도록 붙잡아 둔다.
        await release.future;
        return (status: 200, body: {'accessToken': 'a2', 'refreshToken': 'r2'});
      }
      return r.headers['Authorization'] == 'Bearer a2'
          ? (status: 200, body: null)
          : (status: 401, body: null);
    });
    final client = await fakeApiClient(http);

    final calls = [
      client.dio.get<void>('/a'),
      client.dio.get<void>('/b'),
      client.dio.get<void>('/c'),
    ];
    // 셋 다 401 을 받고 리프레시를 기다리는 자리까지 오게 한다. 요청 수(원 요청 셋 +
    // 리프레시 하나)만 보면 마지막 401 의 인터셉터가 아직 안 돌았을 수 있어, 한 번 더 비운다.
    while (http.requests.length < 4) {
      await Future<void>.delayed(Duration.zero);
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    release.complete();
    await Future.wait(calls);

    expect(http.count('/auth/refresh'), 1);
  });

  test('★ 리프레시가 실패하면 토큰을 지우고 세션 종료를 알린다', () async {
    final http = FakeHttpAdapter((r) async => (status: 401, body: null));
    final storage = MemoryAuthStorage(
      const AuthTokens(accessToken: 'a1', refreshToken: 'r1'),
    );
    final client = ApiClient(storage: storage, httpClientAdapter: http);
    await client.restore();
    var expired = 0;
    client.onSessionExpired = () => expired++;

    await expectLater(
      client.dio.get<void>('/me'),
      throwsA(isA<DioException>()),
    );

    expect(expired, 1);
    expect(client.hasTokens, isFalse);
    expect(http.count('/me'), 1, reason: '되살리지 못했으면 원 요청을 다시 보내지 않는다');
    expect(storage.clears, 1, reason: '영속 저장소의 토큰도 지워야 재시작 때 되살아나지 않는다');
    expect(storage.tokens, isNull);
  });

  test('리프레시 토큰이 없으면 리프레시를 시도하지 않는다', () async {
    final http = FakeHttpAdapter((r) async => (status: 401, body: null));
    final client = await fakeApiClient(http, tokens: null);

    await expectLater(
      client.dio.get<void>('/me'),
      throwsA(isA<DioException>()),
    );
    expect(http.count('/auth/refresh'), 0);
  });

  test('401 이 아닌 실패는 리프레시 없이 그대로 넘긴다', () async {
    final http = FakeHttpAdapter((r) async => (status: 500, body: null));
    final client = await fakeApiClient(http);

    await expectLater(
      client.dio.get<void>('/me'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          500,
        ),
      ),
    );
    expect(http.count('/auth/refresh'), 0);
    expect(http.count('/me'), 1);
  });

  test('리프레시 응답에 refreshToken 이 없으면 있던 것을 남긴다 - 웹 경로', () async {
    final http = FakeHttpAdapter((r) async {
      if (r.path == '/auth/refresh') {
        return (status: 200, body: {'accessToken': 'a2'});
      }
      return r.headers['Authorization'] == 'Bearer a2'
          ? (status: 200, body: null)
          : (status: 401, body: null);
    });
    final client = await fakeApiClient(http);

    await client.dio.get<void>('/me');
    // 다음 리프레시가 같은 r1 으로 나가야 한다 — 비면 그때부터 영영 리프레시를 못 한다.
    expect(await client.refreshAccessToken(), isTrue);
    final refreshBodies = http.requests
        .where((r) => r.path == '/auth/refresh')
        .map((r) => (r.data as Map)['refreshToken']);
    expect(refreshBodies, ['r1', 'r1']);
  });
}
