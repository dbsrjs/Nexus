import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:nexus_app/data/api/api_client.dart';
import 'package:nexus_app/data/auth_storage.dart';
import 'package:nexus_app/domain/models/auth_tokens.dart';

/// 가짜 서버의 응답 하나. [body] 는 JSON 으로 직렬화된다.
typedef FakeReply = ({int status, Object? body});

/// 요청마다 [respond] 를 불러 응답을 만드는 dio 어댑터.
///
/// 소켓을 열지 않으므로 서버 없이 `ApiClient` 의 인터셉터 · `guardApi` 를 그대로 태운다.
/// 보낸 요청은 [requests] 에 남아, 몇 번 · 어떤 토큰으로 갔는지를 단언할 수 있다.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.respond);

  final Future<FakeReply> Function(RequestOptions request) respond;
  final requests = <RequestOptions>[];

  /// 경로가 [path] 인 요청 수.
  int count(String path) => requests.where((r) => r.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = await respond(options);
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 안전 저장소 대신 메모리에 토큰을 둔다. 플랫폼 채널 없이 돈다.
class MemoryAuthStorage implements AuthStorage {
  MemoryAuthStorage([this.tokens]);

  AuthTokens? tokens;
  int clears = 0;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> write(AuthTokens value) async => tokens = value;

  @override
  Future<void> clear() async {
    clears++;
    tokens = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 토큰을 들고 시작하는 [ApiClient].
Future<ApiClient> fakeApiClient(
  FakeHttpAdapter adapter, {
  AuthTokens? tokens = const AuthTokens(accessToken: 'a1', refreshToken: 'r1'),
}) async {
  final client = ApiClient(
    storage: MemoryAuthStorage(tokens),
    httpClientAdapter: adapter,
  );
  await client.restore();
  return client;
}
