import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/core/settable.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/data/socket/socket_event.dart';
import 'package:nexus_app/domain/models/channel.dart';
import 'package:nexus_app/domain/models/space_member.dart';
import 'package:nexus_app/domain/models/user.dart';
import 'package:nexus_app/features/auth/auth_controller.dart';
import 'package:nexus_app/features/realtime/socket_controller.dart';
import 'package:nexus_app/features/space/members_controller.dart';
import 'package:nexus_app/features/space/space_controller.dart';
import 'package:nexus_app/features/voice/voice_controller.dart';
import 'package:nexus_app/features/voice/voice_engine.dart';
import 'package:nexus_app/features/voice/voice_session.dart';
import 'package:nexus_app/features/voice/voice_widgets.dart';

import 'support/nx_host.dart';

/// 20단계 — 음성 채널의 명단 · 통화 상태. 미디어(LiveKit)는 가짜 엔진으로 바꾼다:
/// flutter_webrtc 는 테스트 환경에 플랫폼 구현이 없다. 실제 연결은 웹 빌드로 따로 확인했다.
void main() {
  group('VoiceRosterNotifier', () {
    late StreamController<SocketEvent> events;
    late _FakeVoiceApi api;
    late ProviderContainer container;

    setUp(() async {
      events = StreamController<SocketEvent>.broadcast();
      api = _FakeVoiceApi()
        ..rosterResult = {
          'v1': ['u1'],
        };
      container = ProviderContainer(
        overrides: [
          socketEventsProvider.overrideWith((ref) => events.stream),
          voiceApiProvider.overrideWithValue(api),
          currentSpaceIdProvider.overrideWith(() => SettableNotifier('s1')),
        ],
      );
      container.listen(voiceRosterProvider, (_, _) {}, fireImmediately: true);
      container.listen(socketEventsProvider, (_, _) {}, fireImmediately: true);
      await _settle();
    });

    tearDown(() async {
      container.dispose();
      await events.close();
    });

    Future<void> emit(SocketEvent e) async {
      events.add(e);
      await _settle();
    }

    test('스페이스에 들어가면 처음 값을 받는다', () {
      expect(api.rosterCalls, ['s1']);
      expect(container.read(voiceRosterOfProvider('v1')), ['u1']);
    });

    test('★ voice:state 는 그 채널의 명단을 통째로 바꾼다 — 빈 명단이면 지운다', () async {
      await emit(
        const VoiceStateChanged(
          spaceId: 's1',
          channelId: 'v1',
          userIds: ['u1', 'u2'],
        ),
      );
      expect(container.read(voiceRosterOfProvider('v1')), ['u1', 'u2']);
      await emit(
        const VoiceStateChanged(
          spaceId: 's1',
          channelId: 'v1',
          userIds: ['u2'],
        ),
      );
      expect(container.read(voiceRosterOfProvider('v1')), ['u2']);
      await emit(
        const VoiceStateChanged(spaceId: 's1', channelId: 'v1', userIds: []),
      );
      expect(container.read(voiceRosterOfProvider('v1')), isEmpty);
      expect(container.read(voiceRosterProvider).containsKey('v1'), isFalse);
    });

    test('★ 다시 붙거나 볼 수 있는 채널이 바뀌면 처음 값을 다시 받는다', () async {
      await emit(const SocketConnected());
      await emit(const RoomsInvalidated('s1'));
      expect(api.rosterCalls, ['s1', 's1', 's1']);
    });

    test('처음 값을 못 받아도 던지지 않는다 — 아무도 없어 보일 뿐', () async {
      api.rosterError = const ApiException(ApiFailure.network);
      await emit(const SocketConnected());
      expect(container.read(voiceRosterOfProvider('v1')), ['u1']);
    });
  });

  group('VoiceSessionNotifier', () {
    late _FakeVoiceApi api;
    late List<_FakeEngine> engines;
    late ProviderContainer container;
    late _Auth auth;
    const lounge = Channel(id: 'v1', key: 'lounge', name: '라운지', kind: 'voice');
    const hall = Channel(id: 'v2', key: 'hall', name: '홀', kind: 'voice');

    setUp(() {
      api = _FakeVoiceApi();
      engines = [];
      auth = _Auth();
      container = ProviderContainer(
        overrides: [
          voiceApiProvider.overrideWithValue(api),
          voiceEngineFactoryProvider.overrideWithValue(() {
            final e = _FakeEngine();
            engines.add(e);
            return e;
          }),
          authControllerProvider.overrideWith(() => auth),
        ],
      );
      container.listen(voiceSessionProvider, (_, _) {}, fireImmediately: true);
    });

    tearDown(() => container.dispose());

    VoiceSessionNotifier session() =>
        container.read(voiceSessionProvider.notifier);
    VoiceCall? call() => container.read(voiceSessionProvider);

    test('★ 들어가면 받은 표로 붙고 마이크를 연다', () async {
      final outcome = await session().join(spaceId: 's1', channel: lounge);
      expect(outcome, VoiceJoinOutcome.joined);
      expect(api.ticketCalls, ['s1/v1']);
      expect(engines.single.connectedWith, ('ws://lk', 'tok'));
      expect(engines.single.micOn, isTrue);
      expect(call()?.channelId, 'v1');
      expect(call()?.channelName, '라운지');
      expect(call()?.link, VoiceLink.connected);
      expect(call()?.micOn, isTrue);
    });

    test('★ 읽기 전용이면 마이크를 열지 않고, 켜기도 막는다', () async {
      api.canSpeak = false;
      // 실제 엔진은 토큰의 권한을 그대로 보고한다 — 가짜도 그렇게 맞춘다.
      _FakeEngine.nextCanPublish = false;
      await session().join(spaceId: 's1', channel: lounge);
      expect(engines.single.micCalls, isEmpty);
      await session().setMic(true);
      expect(engines.single.micCalls, isEmpty);
      expect(call()?.canSpeak, isFalse);
    });

    test('마이크를 열지 못해도 통화는 남는다 — 듣기만 한다', () async {
      _FakeEngine.nextMicFails = true;
      final outcome = await session().join(spaceId: 's1', channel: lounge);
      expect(outcome, VoiceJoinOutcome.micUnavailable);
      expect(call()?.channelId, 'v1');
      expect(call()?.micOn, isFalse);
    });

    test('★ 표를 못 받으면 상태를 남기지 않고 던진다', () async {
      api.ticketError = const ApiException(ApiFailure.notFound);
      await expectLater(
        session().join(spaceId: 's1', channel: lounge),
        throwsA(isA<ApiException>()),
      );
      expect(call(), isNull);
      expect(engines, isEmpty);
    });

    test('★ 미디어 서버에 붙지 못하면 엔진을 닫고 던진다', () async {
      _FakeEngine.nextConnectFails = true;
      await expectLater(
        session().join(spaceId: 's1', channel: lounge),
        throwsA(anything),
      );
      expect(call(), isNull);
      expect(engines.single.closed, isTrue);
    });

    test('★ 다른 채널에 들어가면 앞의 통화에서 나온다', () async {
      await session().join(spaceId: 's1', channel: lounge);
      await session().join(spaceId: 's1', channel: hall);
      expect(engines.first.closed, isTrue);
      expect(engines.last.closed, isFalse);
      expect(call()?.channelId, 'v2');
    });

    test('같은 채널을 다시 누르면 아무것도 하지 않는다', () async {
      await session().join(spaceId: 's1', channel: lounge);
      await session().join(spaceId: 's1', channel: lounge);
      expect(engines, hasLength(1));
    });

    test('나가면 엔진을 닫는다', () async {
      await session().join(spaceId: 's1', channel: lounge);
      await session().leave();
      expect(call(), isNull);
      expect(engines.single.closed, isTrue);
    });

    test('★ 서버가 내보내면 통화를 접고 그 채널에 까닭을 남긴다', () async {
      await session().join(spaceId: 's1', channel: lounge);
      engines.single.end(VoiceEnd.removed);
      await _settle();
      expect(call(), isNull);
      expect(engines.single.closed, isTrue);
      final notice = container.read(voiceEndedProvider);
      expect(notice?.channelId, 'v1');
      expect(notice?.reason, VoiceEnd.removed);
    });

    test('다시 들어가면 남긴 까닭을 지운다', () async {
      await session().join(spaceId: 's1', channel: lounge);
      engines.single.end(VoiceEnd.lost);
      await _settle();
      await session().join(spaceId: 's1', channel: lounge);
      expect(container.read(voiceEndedProvider), isNull);
    });

    test('★ 통화 중 권한이 바뀌면(읽기 전용) 상태가 따라온다', () async {
      await session().join(spaceId: 's1', channel: lounge);
      engines.single
        ..canPublishValue = false
        ..micOnValue = false
        ..notifyListeners();
      expect(call()?.canSpeak, isFalse);
      expect(call()?.micOn, isFalse);
    });

    test('말하는 사람이 상태에 실린다', () async {
      await session().join(spaceId: 's1', channel: lounge);
      engines.single
        ..peersValue = const [
          VoicePeer(userId: 'me', speaking: false, micOn: true),
          VoicePeer(userId: 'u2', speaking: true, micOn: true),
        ]
        ..notifyListeners();
      expect(call()?.peers.map((p) => p.speaking), [false, true]);
    });

    test('★ 로그아웃하면 통화에서 나온다', () async {
      await session().join(spaceId: 's1', channel: lounge);
      auth.drop();
      await _settle();
      expect(call(), isNull);
      expect(engines.single.closed, isTrue);
    });

    test('★ 들어가는 중에 나오면 늦게 붙은 연결이 상태를 되살리지 않는다', () async {
      final gate = Completer<void>();
      _FakeEngine.nextConnectGate = gate;
      final joining = session().join(spaceId: 's1', channel: lounge);
      await _settle();
      await session().leave();
      gate.complete();
      expect(await joining, VoiceJoinOutcome.superseded);
      expect(call(), isNull);
      expect(engines.single.closed, isTrue);
    });
  });

  group('화면', () {
    testWidgets('사이드바 명단 — 이름을 보이고, 같은 통화면 마이크 꺼짐을 표시한다', (tester) async {
      final container = ProviderContainer(
        overrides: [
          voiceRosterProvider.overrideWith(
            () => _FixedRoster({
              'v1': ['u1', 'u2'],
            }),
          ),
          voiceSessionProvider.overrideWith(
            () => _FixedSession(
              const VoiceCall(
                spaceId: 's1',
                channelId: 'v1',
                channelName: '라운지',
                link: VoiceLink.connected,
                peers: [
                  VoicePeer(userId: 'u1', speaking: true, micOn: true),
                  VoicePeer(userId: 'u2', speaking: false, micOn: false),
                ],
              ),
            ),
          ),
          spaceMembersProvider.overrideWith(
            (ref) async => const [
              SpaceMemberProfile(userId: 'u1', name: '가나'),
              SpaceMemberProfile(userId: 'u2', name: '다라'),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: nxTestApp(home: const VoiceRosterList(channelId: 'v1')),
        ),
      );
      await tester.pump();
      expect(find.text('가나'), findsOneWidget);
      expect(find.text('다라'), findsOneWidget);
      expect(find.bySemanticsLabel('마이크 꺼짐'), findsOneWidget);
    });

    testWidgets('통화 줄 — 통화가 없으면 아무것도 그리지 않는다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceSessionProvider.overrideWith(() => _FixedSession(null)),
          ],
          child: nxTestApp(home: const VoiceCallBar()),
        ),
      );
      expect(find.text('음성 연결됨'), findsNothing);
    });

    testWidgets('★ 통화 줄 — 읽기 전용이면 마이크 켜기를 누를 수 없다', (tester) async {
      final session = _FixedSession(
        const VoiceCall(
          spaceId: 's1',
          channelId: 'v1',
          channelName: '라운지',
          link: VoiceLink.connected,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [voiceSessionProvider.overrideWith(() => session)],
          child: nxTestApp(home: const VoiceCallBar()),
        ),
      );
      expect(find.text('음성 연결됨'), findsOneWidget);
      expect(find.text('라운지'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('마이크 켜기'));
      await tester.pump();
      expect(session.micRequests, isEmpty);
      await tester.tap(find.bySemanticsLabel('통화에서 나가기'));
      await tester.pump();
      expect(session.left, isTrue);
    });
  });
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

class _FakeVoiceApi implements VoiceApi {
  Map<String, List<String>> rosterResult = const {};
  ApiException? rosterError;
  ApiException? ticketError;
  bool canSpeak = true;
  final rosterCalls = <String>[];
  final ticketCalls = <String>[];

  @override
  Future<bool> enabled() async => true;

  @override
  Future<VoiceTicket> ticket(String spaceId, String channelId) async {
    ticketCalls.add('$spaceId/$channelId');
    final error = ticketError;
    if (error != null) throw error;
    return VoiceTicket(url: 'ws://lk', token: 'tok', canSpeak: canSpeak);
  }

  @override
  Future<Map<String, List<String>>> roster(String spaceId) async {
    rosterCalls.add(spaceId);
    final error = rosterError;
    if (error != null) throw error;
    return rosterResult;
  }
}

class _FakeEngine extends VoiceEngine {
  _FakeEngine()
    : _connectFails = nextConnectFails,
      _micFails = nextMicFails,
      _gate = nextConnectGate,
      canPublishValue = nextCanPublish {
    nextCanPublish = true;
    nextConnectFails = false;
    nextMicFails = false;
    nextConnectGate = null;
  }

  static bool nextCanPublish = true;
  static bool nextConnectFails = false;
  static bool nextMicFails = false;
  static Completer<void>? nextConnectGate;

  final bool _connectFails;
  final bool _micFails;
  final Completer<void>? _gate;

  (String, String)? connectedWith;
  final micCalls = <bool>[];
  bool closed = false;
  VoiceLink linkValue = VoiceLink.connecting;
  List<VoicePeer> peersValue = const [];
  bool micOnValue = false;
  bool canPublishValue;
  VoiceEnd? endedValue;

  void end(VoiceEnd reason) {
    endedValue = reason;
    notifyListeners();
  }

  @override
  VoiceLink get link => linkValue;
  @override
  List<VoicePeer> get peers => peersValue;
  @override
  bool get micOn => micOnValue;
  @override
  bool get canPublish => canPublishValue;
  @override
  bool get audioBlocked => false;
  @override
  VoiceEnd? get ended => endedValue;

  @override
  Future<void> connect(String url, String token) async {
    await _gate?.future;
    if (_connectFails) throw StateError('미디어 서버에 닿지 못함');
    connectedWith = (url, token);
    linkValue = VoiceLink.connected;
    _notify();
  }

  bool _disposed = false;

  /// 닫힌 뒤에 끝난 연결은 알리지 않는다 — 실제 엔진도 닫을 때 듣는 쪽을 떼어 낸다. 여기서 던지면
  /// 세대 검사가 없어도 catch 로 빠져 테스트가 통과해 버린다(돌연변이로 확인했다).
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Future<void> setMic(bool on) async {
    if (_micFails) throw StateError('권한 거부');
    micCalls.add(on);
    micOnValue = on;
    _notify();
  }

  @override
  Future<void> startAudio() async {}

  @override
  Future<void> close() async => closed = true;
}

class _Auth extends AuthController {
  @override
  AuthState build() =>
      const AuthSignedIn(User(id: 'me', email: 'me@x.test', name: '나'));

  void drop() => state = const AuthSignedOut();
}

class _FixedRoster extends VoiceRosterNotifier {
  _FixedRoster(this.value);
  final Map<String, List<String>> value;
  @override
  Map<String, List<String>> build() => value;
}

class _FixedSession extends VoiceSessionNotifier {
  _FixedSession(this.value);
  final VoiceCall? value;
  final micRequests = <bool>[];
  bool left = false;

  @override
  VoiceCall? build() => value;

  @override
  Future<void> setMic(bool on) async => micRequests.add(on);

  @override
  Future<void> leave() async => left = true;
}
