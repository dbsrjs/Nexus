import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/data/api/notifications_api.dart';
import 'package:nexus_app/data/socket/socket_event.dart';
import 'package:nexus_app/features/auth/auth_controller.dart';
import 'package:nexus_app/features/notifications/notifications_controller.dart';
import 'package:nexus_app/features/notifications/notifications_screen.dart';
import 'package:nexus_app/features/realtime/socket_controller.dart';
import 'package:nexus_app/features/settings/notifications_section.dart';
import 'package:nexus_app/features/settings/settings_widgets.dart';
import 'package:nexus_app/ui/ui.dart';
import 'package:nexus_app/features/shell/app_shell.dart';
import 'package:nexus_app/features/space/members_controller.dart';
import 'package:nexus_app/features/space/space_controller.dart';

import 'support/nx_host.dart';

/// 18단계 인앱 알림 — 모델 · 문구 · 갈 곳 · 목록 상태 · 한 줄 위젯.
void main() {
  group('NotificationItem.fromJson', () {
    test('목록 한 줄을 읽는다', () {
      final n = _item(type: 'reply', threadId: 'p1', kind: 'dm');
      expect(n.type, NotificationType.reply);
      expect(n.threadId, 'p1');
      expect(n.isDm, isTrue);
      expect(n.actorName, '가나');
      expect(n.read, isFalse);
    });

    test('★ 모르는 종류는 other — 서버가 종류를 늘려도 앱이 죽지 않는다', () {
      expect(_item(type: 'issue_assigned').type, NotificationType.other);
    });
  });

  group('notificationHeadline', () {
    test('채널이면 채널 이름을, DM 이면 빼고', () {
      expect(notificationHeadline(_item(type: 'mention')), '가나 님이 #개발 에서 나를 멘션했습니다');
      expect(notificationHeadline(_item(type: 'mention', kind: 'dm')), '가나 님이 나를 멘션했습니다');
      expect(notificationHeadline(_item(type: 'dm', kind: 'dm')), '가나 님이 메시지를 보냈습니다');
      expect(notificationHeadline(_item(type: 'broadcast')), '가나 님이 #개발 에서 모두를 불렀습니다');
      expect(notificationHeadline(_item(type: 'reply')), '가나 님이 #개발 에서 내 글에 답글을 달았습니다');
    });
  });

  test('★ 답글은 스레드로, 나머지는 채널로 간다', () {
    expect(notificationTarget('s1', _item()), '/s/s1/c/c1');
    expect(notificationTarget('s1', _item(threadId: 'p1')), '/s/s1/c/c1/t/p1');
  });

  test('알림함은 모바일 다섯째 탭이다', () {
    expect(shellTabFor('/s/a/notifications'), 4);
  });

  test('시각 — 오늘은 시:분, 올해는 월/일, 지난해는 연도까지', () {
    final now = DateTime(2026, 10, 5, 18);
    expect(notificationTime(DateTime(2026, 10, 5, 9, 7), now: now), '09:07');
    expect(notificationTime(DateTime(2026, 10, 3, 9), now: now), '10/3');
    expect(notificationTime(DateTime(2025, 12, 31, 9), now: now), '2025/12/31');
  });

  group('NotificationsNotifier', () {
    late StreamController<SocketEvent> events;
    late ProviderContainer container;
    late _FakeApi api;

    setUp(() async {
      events = StreamController<SocketEvent>.broadcast();
      api = _FakeApi([_item(id: 'n2'), _item(id: 'n1')]);
      container = ProviderContainer(
        overrides: [
          socketEventsProvider.overrideWith((ref) => events.stream),
          authControllerProvider.overrideWith(() => _SignedOut()),
          notificationsApiProvider.overrideWithValue(api),
        ],
      );
      container.read(currentSpaceIdProvider.notifier).set('s1');
      // Riverpod 3 은 구독자가 없는 provider 를 멈춘다 — listen 으로 붙든다(CLAUDE.md §2).
      container.listen(notificationsProvider, (_, _) {}, fireImmediately: true);
      container.listen(socketEventsProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    tearDown(() async {
      container.dispose();
      await events.close();
    });

    Future<void> emit(SocketEvent e) async {
      events.add(e);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    List<String> ids() => container.read(notificationsProvider).items.map((n) => n.id).toList();

    test('첫 쪽을 받는다', () {
      expect(ids(), ['n2', 'n1']);
      expect(container.read(notificationsProvider).loading, isFalse);
    });

    test('★ 새 알림은 맨 위에 — 다른 스페이스의 것은 버린다', () async {
      await emit(NotificationNew(spaceId: 's2', notification: _item(id: 'x')));
      await emit(NotificationNew(spaceId: 's1', notification: _item(id: 'n3')));
      expect(ids(), ['n3', 'n2', 'n1']);
    });

    test('같은 알림이 두 번 와도 한 줄', () async {
      await emit(NotificationNew(spaceId: 's1', notification: _item(id: 'n2')));
      expect(ids(), ['n2', 'n1']);
    });

    test('★ 다른 기기에서 읽은 것은 읽음으로 — ids=null 은 전부', () async {
      await emit(const NotificationRead(spaceId: 's1', ids: ['n1']));
      var items = container.read(notificationsProvider).items;
      expect(items.firstWhere((n) => n.id == 'n1').read, isTrue);
      expect(items.firstWhere((n) => n.id == 'n2').read, isFalse);

      await emit(const NotificationRead(spaceId: 's1', ids: null));
      items = container.read(notificationsProvider).items;
      expect(items.every((n) => n.read), isTrue);
    });

    test('누르면 화면을 먼저 읽음으로 바꾸고 서버에 알린다', () async {
      final first = container.read(notificationsProvider).items.first;
      await container.read(notificationsProvider.notifier).markRead(first);
      expect(container.read(notificationsProvider).items.first.read, isTrue);
      expect(api.readIds, ['n2']);
    });
  });

  group('NotificationTile', () {
    Future<void> pump(WidgetTester tester, NotificationItem item, {VoidCallback? onPressed}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memberNamesProvider.overrideWithValue(const {'11111111-2222-4333-8444-555555555555': '나리'}),
          ],
          child: nxTestApp(
            home: NotificationTile(item: item, onPressed: onPressed ?? () {}),
          ),
        ),
      );
    }

    testWidgets('★ 멘션은 이름으로 · 서식은 벗겨 보인다', (tester) async {
      await pump(tester, _item(body: '**급함** <@11111111-2222-4333-8444-555555555555> 봐 주세요'));
      expect(find.text('급함 @나리 봐 주세요'), findsOneWidget);
      expect(find.text('가나 님이 #개발 에서 나를 멘션했습니다'), findsOneWidget);
    });

    testWidgets('안 읽은 줄에만 점이 있다', (tester) async {
      await pump(tester, _item());
      expect(find.byKey(const ValueKey('notification-unread-dot')), findsOneWidget);
      await pump(tester, _item(read: true));
      expect(find.byKey(const ValueKey('notification-unread-dot')), findsNothing);
    });

    testWidgets('★ 삭제된 메시지는 본문 대신 안내', (tester) async {
      await pump(tester, _item(body: '', deleted: true));
      expect(find.text('삭제된 메시지입니다'), findsOneWidget);
    });

    testWidgets('본문 없이 파일만 보낸 메시지', (tester) async {
      await pump(tester, _item(body: ''));
      expect(find.text('파일을 보냈습니다'), findsOneWidget);
    });

    testWidgets('누르면 콜백', (tester) async {
      var pressed = 0;
      await pump(tester, _item(), onPressed: () => pressed++);
      await tester.tap(find.byType(NotificationTile));
      expect(pressed, 1);
    });
  });

  group('알림 스위치(설정 창)', () {
    testWidgets('★ 스위치 하나를 끄면 그 값만 보낸다', (tester) async {
      final api = _FakeApi(const []);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsApiProvider.overrideWithValue(api),
            spacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: nxTestApp(home: const NotificationsSection()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('다이렉트 메시지'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('다이렉트 메시지 알림'));
      await tester.pumpAndSettle();
      expect(api.patches, [
        {'dms': false},
      ]);
    });

    testWidgets('저장에 실패하면 되돌리고 곁에 알린다', (tester) async {
      final api = _FakeApi(const [])..failPatch = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsApiProvider.overrideWithValue(api),
            spacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: nxTestApp(home: const NotificationsSection()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('멘션 알림'));
      await tester.pumpAndSettle();
      final mention = tester.widget<NxSwitch>(
        find.byWidgetPredicate((w) => w is NxSwitch && w.label == '멘션 알림'),
      );
      expect(mention.value, isTrue, reason: '저장하지 못한 값을 꺼진 채로 두면 거짓말이다');
      expect(find.byType(SettingsError), findsOneWidget);
    });
  });
}

NotificationItem _item({
  String id = 'n1',
  String type = 'mention',
  String kind = 'text',
  String? threadId,
  String body = 'hello',
  bool deleted = false,
  bool read = false,
}) =>
    NotificationItem.fromJson({
      'id': id,
      'type': type,
      'read': read,
      'createdAt': '2026-10-05T09:00:00.000Z',
      'channelId': 'c1',
      'messageId': 'm-$id',
      'threadId': threadId,
      'actor': {'id': 'u-ga', 'name': '가나', 'avatarUrl': null},
      'channel': {'name': '개발', 'kind': kind},
      'body': body,
      'deleted': deleted,
    });

class _FakeApi implements NotificationsApi {
  _FakeApi(this.items);

  final List<NotificationItem> items;
  final readIds = <String>[];

  @override
  Future<NotificationPage> list(String spaceId, {String? cursor, int limit = 30}) async =>
      NotificationPage(items: items, nextCursor: null);

  @override
  Future<void> markRead(String spaceId, String id) async => readIds.add(id);

  var current = const NotificationSettings(mentions: true, broadcast: true, dms: true, replies: true);
  final patches = <Map<String, bool>>[];
  var failPatch = false;

  @override
  Future<NotificationSettings> settings() async => current;

  @override
  Future<NotificationSettings> updateSettings({
    bool? mentions,
    bool? broadcast,
    bool? dms,
    bool? replies,
  }) async {
    if (failPatch) throw const ApiException(ApiFailure.server);
    patches.add({
      'mentions': ?mentions,
      'broadcast': ?broadcast,
      'dms': ?dms,
      'replies': ?replies,
    });
    current = NotificationSettings(
      mentions: mentions ?? current.mentions,
      broadcast: broadcast ?? current.broadcast,
      dms: dms ?? current.dms,
      replies: replies ?? current.replies,
    );
    return current;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SignedOut extends AuthController {
  @override
  AuthState build() => const AuthSignedOut();
}
