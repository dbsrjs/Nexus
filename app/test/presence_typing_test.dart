import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/socket/socket_event.dart';
import 'package:nexus_app/domain/models/message.dart';
import 'package:nexus_app/domain/models/presence.dart';
import 'package:nexus_app/features/auth/auth_controller.dart';
import 'package:nexus_app/features/presence/typing_controller.dart';
import 'package:nexus_app/features/realtime/socket_controller.dart';

/// 17단계 D21~D24 — 「입력 중」 상태와 문구.
void main() {
  group('typingLabel', () {
    test('아무도 없으면 null', () => expect(typingLabel(const []), isNull));
    test('한 명 · 두 명은 이름을', () {
      expect(typingLabel(['가나']), '가나 님이 입력 중…');
      expect(typingLabel(['가나', '다라']), '가나, 다라 님이 입력 중…');
    });
    test('셋 이상은 「여러 명」', () => expect(typingLabel(['a', 'b', 'c']), '여러 명이 입력 중…'));
  });

  test('presenceFromWire — 모르는 값은 오프라인', () {
    expect(presenceFromWire('online'), Presence.online);
    expect(presenceFromWire('away'), Presence.away);
    expect(presenceFromWire('offline'), Presence.offline);
    expect(presenceFromWire(null), Presence.offline);
  });

  group('TypingNotifier', () {
    late StreamController<SocketEvent> events;
    late ProviderContainer container;

    setUp(() async {
      events = StreamController<SocketEvent>.broadcast();
      container = ProviderContainer(
        overrides: [
          socketEventsProvider.overrideWith((ref) => events.stream),
          authControllerProvider.overrideWith(() => _SignedOut()),
        ],
      );
      container.listen(typingProvider, (_, _) {}, fireImmediately: true);
      container.listen(socketEventsProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() async {
      container.dispose();
      await events.close();
    });

    Future<void> emit(SocketEvent e) async {
      events.add(e);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    List<String> usersIn(String channelId, [String? parentId]) =>
        container.read(typingUsersProvider(typingKey(channelId, parentId)));

    test('★ 채널과 스레드를 따로 모은다', () async {
      await emit(const Typing(spaceId: 's', channelId: 'c', userId: 'u1'));
      await emit(const Typing(spaceId: 's', channelId: 'c', userId: 'u2', parentId: 'p'));
      expect(usersIn('c'), ['u1']);
      expect(usersIn('c', 'p'), ['u2']);
    });

    test('★ 그 사람의 새 메시지가 오면 지운다(D23)', () async {
      await emit(const Typing(spaceId: 's', channelId: 'c', userId: 'u1'));
      await emit(MessageNew(spaceId: 's', channelId: 'c', message: _message('u1')));
      expect(usersIn('c'), isEmpty);
    });

    test('다른 사람의 메시지로는 지우지 않는다', () async {
      await emit(const Typing(spaceId: 's', channelId: 'c', userId: 'u1'));
      await emit(MessageNew(spaceId: 's', channelId: 'c', message: _message('u2')));
      expect(usersIn('c'), ['u1']);
    });
  });
}

class _SignedOut extends AuthController {
  @override
  AuthState build() => const AuthSignedOut();
}

Message _message(String authorId) => Message.fromJson({
      'id': 'm-$authorId',
      'channelId': 'c',
      'body': 'hi',
      'createdAt': '2026-10-05T00:00:00.000Z',
      'author': {'id': authorId, 'name': authorId},
    });
