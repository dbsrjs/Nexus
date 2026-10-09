import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/notifications_api.dart';
import 'package:nexus_app/data/settings_storage.dart';
import 'package:nexus_app/data/socket/socket_event.dart';
import 'package:nexus_app/features/desktop/desktop_shell.dart';
import 'package:nexus_app/features/desktop/os_notifications.dart';
import 'package:nexus_app/features/notifications/notifications_controller.dart';
import 'package:nexus_app/features/realtime/socket_controller.dart';
import 'package:nexus_app/features/settings/notifications_section.dart';
import 'package:nexus_app/features/settings/settings_widgets.dart';
import 'package:nexus_app/features/settings/theme_controller.dart';
import 'package:nexus_app/features/space/members_controller.dart';
import 'package:nexus_app/features/space/space_controller.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/nx_host.dart';

/// «마지막» 데스크톱 · 웹 알림 — 언제 띄우나 · 무엇을 띄우나 · 누르면 어디로 · 설정 스위치.
///
/// 실제 OS(Windows 트레이 · 브라우저 Notification)는 여기서 돌지 않는다 — 그 둘은
/// [DesktopShell] 뒤에 있고, 이 파일은 그 앞의 판단만 본다.
void main() {
  group('showOsNotification — 띄울지', () {
    Future<bool> show(
      _FakeShell shell, {
      bool enabled = true,
      NotificationItem? item,
    }) => showOsNotification(
      shell: shell,
      enabled: enabled,
      spaceId: 's1',
      item: item ?? _item(),
      names: const {'11111111-2222-4333-8444-555555555555': '다라'},
    );

    test('★ 창을 보고 있지 않으면 띄운다 — 머리 문구 · 미리보기 · 채널 태그 · 갈 곳', () async {
      final shell = _FakeShell();
      expect(
        await show(
          shell,
          item: _item(
            body: '**급함** <@11111111-2222-4333-8444-555555555555> 봐 주세요',
          ),
        ),
        isTrue,
      );
      final sent = shell.sent.single;
      expect(sent.title, '가나 님이 #개발 에서 나를 멘션했습니다');
      expect(sent.body, '급함 @다라 봐 주세요');
      expect(sent.tag, 'c1');
      expect(sent.payload, '/s/s1/c/c1');
    });

    test('답글이면 스레드로 간다', () async {
      final shell = _FakeShell();
      await show(
        shell,
        item: _item(type: 'reply', threadId: 'p1'),
      );
      expect(shell.sent.single.payload, '/s/s1/c/c1/t/p1');
    });

    test('★ 보고 있으면 띄우지 않는다 — 알림함 뱃지가 이미 알린다', () async {
      final shell = _FakeShell()..focused = true;
      expect(await show(shell), isFalse);
      expect(shell.sent, isEmpty);
    });

    test('이 기기에서 껐으면 띄우지 않는다', () async {
      final shell = _FakeShell();
      expect(await show(shell, enabled: false), isFalse);
      expect(shell.sent, isEmpty);
    });

    test('허락을 받지 못했으면(웹) 띄우지 않는다', () async {
      for (final p in [
        NotifyPermission.notYet,
        NotifyPermission.denied,
        NotifyPermission.unsupported,
      ]) {
        final shell = _FakeShell()..permission = p;
        expect(await show(shell), isFalse, reason: '$p');
        expect(shell.sent, isEmpty);
      }
    });

    test('이미 읽은 알림(다른 기기에서 읽음)은 띄우지 않는다', () async {
      final shell = _FakeShell();
      expect(await show(shell, item: _item(read: true)), isFalse);
    });
  });

  group('osNotificationsProvider — 소켓 · 누르기', () {
    late _FakeShell shell;
    late StreamController<SocketEvent> events;
    late List<String> went;
    late ProviderContainer container;

    setUp(() async {
      shell = _FakeShell();
      events = StreamController<SocketEvent>.broadcast();
      went = [];
      container = ProviderContainer(
        overrides: [
          desktopShellProvider.overrideWithValue(shell),
          socketEventsProvider.overrideWith((ref) => events.stream),
          settingsStorageProvider.overrideWithValue(_FakeStorage(stored: true)),
          memberNamesProvider.overrideWithValue(const {}),
          desktopNavigateProvider.overrideWithValue(went.add),
        ],
      );
      // main.dart 처럼 붙든다 — 구독자가 없으면 Riverpod 3 이 멈춘다(CLAUDE.md §2).
      container.listen(osNotificationsProvider, (_, _) {});
      container.listen(desktopNotifyEnabledProvider, (_, _) {});
      container.listen(socketEventsProvider, (_, _) {}, fireImmediately: true);
      await pumpEventQueue();
    });

    tearDown(() async {
      container.dispose();
      await events.close();
    });

    test('★ 지금 스페이스가 아닌 곳의 알림도 띄운다(사용자 룸으로 온다)', () async {
      events.add(NotificationNew(spaceId: 's9', notification: _item()));
      await pumpEventQueue();
      expect(shell.sent.single.payload, '/s/s9/c/c1');
    });

    test('다른 소켓 이벤트에는 반응하지 않는다', () async {
      events.add(const NotificationRead(spaceId: 's1', ids: ['n1']));
      await pumpEventQueue();
      expect(shell.sent, isEmpty);
    });

    test('★ 누르면 창을 꺼내고 그 자리로 간다', () async {
      shell.clicks$.add('/s/s1/c/c1/t/p1');
      await pumpEventQueue();
      expect(went, ['/s/s1/c/c1/t/p1']);
      expect(shell.focusCount, 1);
    });

    test('★ 앱 밖 주소는 따르지 않는다(딥링크와 같은 규칙)', () async {
      for (final evil in [
        '//evil.example',
        'https://evil.example',
        '/login',
        '',
      ]) {
        shell.clicks$.add(evil);
      }
      await pumpEventQueue();
      expect(went, isEmpty);
    });
  });

  group('이 기기 스위치 값', () {
    test('저장된 값을 읽어 온다 — 읽기 전에는 꺼 둔다', () async {
      final container = ProviderContainer(
        overrides: [
          settingsStorageProvider.overrideWithValue(
            _FakeStorage(stored: false),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(desktopNotifyEnabledProvider, (_, _) {});
      expect(container.read(desktopNotifyEnabledProvider), isFalse);
      await pumpEventQueue();
      expect(container.read(desktopNotifyEnabledProvider), isFalse);
    });

    test('읽기 전에 사용자가 바꿨으면 늦게 온 저장값이 덮지 않는다', () async {
      final storage = _FakeStorage(stored: false);
      final container = ProviderContainer(
        overrides: [settingsStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      container.listen(desktopNotifyEnabledProvider, (_, _) {});
      container.read(desktopNotifyEnabledProvider.notifier).set(true);
      await pumpEventQueue();
      expect(container.read(desktopNotifyEnabledProvider), isTrue);
      expect(storage.written, [true]);
    });
  });

  group('설정 창 「이 기기」', () {
    Future<void> pump(
      WidgetTester tester,
      _FakeShell shell, {
      bool stored = true,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            desktopShellProvider.overrideWithValue(shell),
            settingsStorageProvider.overrideWithValue(
              _FakeStorage(stored: stored),
            ),
            notificationsApiProvider.overrideWithValue(_FakeApi()),
            spacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: nxTestApp(home: const NotificationsSection()),
        ),
      );
      await tester.pumpAndSettle();
    }

    NxSwitch deviceSwitch(WidgetTester tester) => tester.widget<NxSwitch>(
      find.byWidgetPredicate((w) => w is NxSwitch && w.label == '데스크톱 알림'),
    );

    testWidgets('★ 웹 — 처음 켜면 브라우저에 묻고, 허락하면 켜진다', (tester) async {
      final shell = _FakeShell(kind: DesktopShellKind.web)
        ..permission = NotifyPermission.notYet
        ..answer = NotifyPermission.granted;
      await pump(tester, shell);
      expect(
        deviceSwitch(tester).value,
        isFalse,
        reason: '허락 전에는 켜져 보이면 거짓말이다',
      );

      await tester.tap(find.bySemanticsLabel('데스크톱 알림'));
      await tester.pumpAndSettle();
      expect(shell.asked, 1);
      expect(deviceSwitch(tester).value, isTrue);
    });

    testWidgets('웹 — 거절하면 꺼진 채 · 푸는 법을 알린다', (tester) async {
      final shell = _FakeShell(kind: DesktopShellKind.web)
        ..permission = NotifyPermission.notYet
        ..answer = NotifyPermission.denied;
      await pump(tester, shell);
      await tester.tap(find.bySemanticsLabel('데스크톱 알림'));
      await tester.pumpAndSettle();
      expect(deviceSwitch(tester).value, isFalse);
      expect(
        deviceSwitch(tester).onChanged,
        isNull,
        reason: '다시 눌러도 브라우저는 묻지 않는다',
      );
      expect(find.byType(SettingsError), findsOneWidget);
    });

    testWidgets('Windows — 묻지 않고 끄고 켠다 · 트레이 안내', (tester) async {
      final shell = _FakeShell();
      await pump(tester, shell);
      expect(deviceSwitch(tester).value, isTrue);
      expect(find.textContaining('트레이'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('데스크톱 알림'));
      await tester.pumpAndSettle();
      expect(deviceSwitch(tester).value, isFalse);
      expect(shell.asked, 0);
    });

    testWidgets('데스크톱 알림이 없는 기기는 스위치 대신 사실을 적는다', (tester) async {
      await pump(
        tester,
        _FakeShell(kind: DesktopShellKind.none)
          ..permission = NotifyPermission.unsupported,
      );
      expect(
        find.byWidgetPredicate((w) => w is NxSwitch && w.label == '데스크톱 알림'),
        findsNothing,
      );
      expect(find.textContaining('알림함에서 확인하세요'), findsOneWidget);
    });
  });
}

class _Sent {
  _Sent(this.title, this.body, this.tag, this.payload);
  final String title;
  final String body;
  final String tag;
  final String payload;
}

class _FakeShell implements DesktopShell {
  _FakeShell({this.kind = DesktopShellKind.windows});

  @override
  final DesktopShellKind kind;

  @override
  NotifyPermission permission = NotifyPermission.granted;

  /// requestPermission 이 돌려줄 답.
  NotifyPermission answer = NotifyPermission.granted;
  int asked = 0;
  bool focused = false;
  int focusCount = 0;
  final sent = <_Sent>[];
  final clicks$ = StreamController<String>.broadcast();

  @override
  Future<NotifyPermission> requestPermission() async {
    asked++;
    return permission = answer;
  }

  @override
  Future<bool> isFocused() async => focused;

  @override
  Future<bool> notify({
    required String title,
    required String body,
    required String tag,
    required String payload,
  }) async {
    sent.add(_Sent(title, body, tag, payload));
    return true;
  }

  @override
  Stream<String> get clicks => clicks$.stream;

  @override
  Future<void> focus() async => focusCount++;
}

class _FakeStorage implements SettingsStorage {
  _FakeStorage({required this.stored});

  final bool stored;
  final written = <bool>[];

  @override
  Future<bool> readDesktopNotifications() async => stored;

  @override
  Future<void> writeDesktopNotifications(bool enabled) async =>
      written.add(enabled);

  @override
  Future<ThemePreference> readThemePreference() async => ThemePreference.system;

  @override
  Future<void> writeThemePreference(ThemePreference mode) async {}
}

class _FakeApi implements NotificationsApi {
  @override
  Future<NotificationSettings> settings() async => const NotificationSettings(
    mentions: true,
    broadcast: true,
    dms: true,
    replies: true,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

NotificationItem _item({
  String type = 'mention',
  String? threadId,
  String body = 'hello',
  bool read = false,
}) => NotificationItem.fromJson({
  'id': 'n1',
  'type': type,
  'read': read,
  'createdAt': '2026-10-09T09:00:00.000Z',
  'channelId': 'c1',
  'messageId': 'm1',
  'threadId': threadId,
  'actor': {'id': 'u-ga', 'name': '가나', 'avatarUrl': null},
  'channel': {'name': '개발', 'kind': 'text'},
  'body': body,
  'deleted': false,
});
