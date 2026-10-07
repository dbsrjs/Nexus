import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/api_client.dart';
import 'package:nexus_app/data/repositories/message_repository.dart';
import 'package:nexus_app/data/socket/socket_client.dart';
import 'package:nexus_app/data/socket/socket_event.dart';
import 'package:nexus_app/features/auth/auth_controller.dart';
import 'package:nexus_app/features/chat/message_controller.dart';
import 'package:nexus_app/domain/models/space_member.dart';
import 'package:nexus_app/features/realtime/socket_controller.dart';
import 'package:nexus_app/features/space/members_controller.dart';

/// 소켓 핸드셰이크 거부 → 토큰 갱신 → 재연결 경로.
///
/// **액세스 토큰 만료(15분)를 기다려야 재현되던 경로라** 실기기로 한 번 본 것이
/// 전부였다(CLAUDE.md §5 빚). 서버 쪽 약속 — 만료 토큰은 `unauthorized` 로 거부,
/// 새 토큰은 받아들임 — 은 `check:realtime` 이 보고, 여기서는 그 신호를 받은
/// 앱이 무엇을 하는지만 본다.
void main() {
  late StreamController<SocketEvent> events;
  late _FakeApi api;
  late _FakeSocket socket;
  late _FakeMessages messages;
  late ProviderContainer container;
  late int memberBuilds;

  setUp(() {
    memberBuilds = 0;
    events = StreamController<SocketEvent>();
    api = _FakeApi();
    socket = _FakeSocket();
    messages = _FakeMessages();
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        socketClientProvider.overrideWithValue(socket),
        messageRepositoryProvider.overrideWithValue(messages),
        socketEventsProvider.overrideWith((ref) => events.stream),
        spaceMembersProvider.overrideWith((ref) async {
          memberBuilds++;
          return const <SpaceMemberProfile>[];
        }),
      ],
    );
    // 리스너를 살린다 — 앱에서는 main.dart 가 watch 한다. **read 로는 안 된다** —
    // Riverpod 3 은 구독자가 없는 provider 를 멈춰 그 안의 ref.listen 도 멈춘다.
    container.listen(realtimeChannelSyncProvider, (_, _) {});
    addTearDown(() {
      container.dispose();
      events.close();
    });
  });

  /// 이벤트 하나를 흘리고 `.then` 으로 이어지는 갱신까지 끝나기를 기다린다.
  Future<void> emit(SocketEvent event) async {
    events.add(event);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('★ 핸드셰이크가 거부되면 토큰을 갱신하고 새 토큰으로 다시 붙는다', () async {
    await emit(const SocketUnauthorized());
    expect(api.refreshes, 1);
    expect(socket.reconnects, 1);
  });

  test('★ 새 토큰으로도 거부되면 다시 갱신하지 않는다 - 무한 리프레시는 재사용 탐지에 걸린다', () async {
    await emit(const SocketUnauthorized());
    // 같은 이벤트가 연달아 오면 값이 같아 리스너가 불리지 않을 수 있다.
    // 사이에 다른 이벤트를 끼워 두 번째 거부가 실제로 리스너에 닿게 한다.
    await emit(const SocketDisconnected('io server disconnect'));
    await emit(const SocketUnauthorized());
    expect(api.refreshes, 1);
    expect(socket.reconnects, 1);
  });

  test('★ 한 번 붙은 뒤의 거부는 다시 갱신한다 - 앱을 오래 켜 두면 토큰이 또 만료된다', () async {
    await emit(const SocketUnauthorized());
    await emit(const SocketConnected());
    await emit(const SocketUnauthorized());
    expect(api.refreshes, 2);
    expect(socket.reconnects, 2);
  });

  test('갱신이 실패하면 다시 붙지 않는다 - 로그인 화면으로 가는 것은 ApiClient 몫이다', () async {
    api.succeeds = false;
    await emit(const SocketUnauthorized());
    expect(api.refreshes, 1);
    expect(socket.reconnects, 0);
  });

  test('★ 다시 붙으면 쌓인 전송 큐를 내보낸다 - 갱신 경로가 없으면 이 계기가 영영 오지 않는다', () async {
    await emit(const SocketUnauthorized());
    await emit(const SocketConnected());
    expect(messages.flushes, 1);
  });

  test('★ 다시 붙으면 멤버 목록도 다시 받는다 - 오프라인으로 켜면 빈 목록이 남아 DM 상대가 「나간 사람」이 됐다', () async {
    container.listen(spaceMembersProvider, (_, _) {});
    await container.read(spaceMembersProvider.future);
    expect(memberBuilds, 1);

    await emit(const SocketConnected());
    await container.read(spaceMembersProvider.future);
    expect(memberBuilds, 2);
  });
}

class _FakeApi implements ApiClient {
  int refreshes = 0;
  bool succeeds = true;

  @override
  Future<bool> refreshAccessToken() async {
    refreshes++;
    return succeeds;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSocket implements SocketClient {
  int reconnects = 0;

  @override
  void reconnectWithFreshToken() => reconnects++;

  @override
  void syncRooms() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMessages implements MessageRepository {
  int flushes = 0;

  @override
  Future<int> flush() async {
    flushes++;
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
