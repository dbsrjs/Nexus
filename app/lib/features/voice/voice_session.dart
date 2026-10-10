import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/channel.dart';
import '../auth/auth_controller.dart';
import 'voice_controller.dart';
import 'voice_engine.dart';

export 'voice_engine.dart'
    show
        ScreenShareMode,
        ScreenSource,
        VoiceEnd,
        VoiceLink,
        VoicePeer,
        listScreenSources,
        screenShareMode;

/// 내가 들어가 있는 통화(20단계). 한 번에 하나다 — 다른 채널에 들어가면 앞의 것에서 나온다.
@immutable
class VoiceCall {
  const VoiceCall({
    required this.spaceId,
    required this.channelId,
    required this.channelName,
    this.link = VoiceLink.connecting,
    this.peers = const [],
    this.micOn = false,
    this.canSpeak = false,
    this.audioBlocked = false,
    this.screenShareOn = false,
    this.screenSharers = const [],
  });

  final String spaceId;
  final String channelId;

  /// 들어갈 때의 이름. 다른 스페이스로 옮겨 가도 통화는 이어지고, 그때 그 스페이스의 채널 목록에는
  /// 이 채널이 없다 — 통화 줄이 이름을 잃지 않게 들고 다닌다.
  final String channelName;
  final VoiceLink link;
  final List<VoicePeer> peers;
  final bool micOn;

  /// 지금 말할 수 있나. 통화 중에 채널이 읽기 전용이 되면 거짓으로 바뀐다(서버가 권한을 내린다).
  final bool canSpeak;
  final bool audioBlocked;

  /// 내가 화면을 공유 중인가.
  final bool screenShareOn;

  /// 화면을 공유 중인 사람(나 포함) — 통화 화면이 크게 보일 화면을 고른다.
  final List<String> screenSharers;

  VoiceCall copyWith({
    VoiceLink? link,
    List<VoicePeer>? peers,
    bool? micOn,
    bool? canSpeak,
    bool? audioBlocked,
    bool? screenShareOn,
    List<String>? screenSharers,
  }) => VoiceCall(
    spaceId: spaceId,
    channelId: channelId,
    channelName: channelName,
    link: link ?? this.link,
    peers: peers ?? this.peers,
    micOn: micOn ?? this.micOn,
    canSpeak: canSpeak ?? this.canSpeak,
    audioBlocked: audioBlocked ?? this.audioBlocked,
    screenShareOn: screenShareOn ?? this.screenShareOn,
    screenSharers: screenSharers ?? this.screenSharers,
  );
}

/// 들어간 결과. 들어가는 것 자체가 실패하면 [ApiException] 등을 던진다.
enum VoiceJoinOutcome {
  joined,

  /// 들어갔지만 마이크를 열지 못했다(권한 거부 · 장치 없음) — 듣기만 한다.
  micUnavailable,

  /// 그사이 다른 채널을 눌렀거나 나왔다.
  superseded,
}

/// 미디어 연결을 만드는 곳. 테스트가 가짜로 바꾼다 — 실제 것은 플랫폼 구현(flutter_webrtc)이 있어야 돈다.
final voiceEngineFactoryProvider = Provider<VoiceEngine Function()>(
  (_) => LiveKitVoiceEngine.new,
);

/// 이 기기의 화면 공유 방식. 테스트가 바꾼다 — flutter_test 의 기본 플랫폼은 Android 라 늘 `unsupported` 다.
final screenShareModeProvider = Provider<ScreenShareMode>(
  (_) => screenShareMode(),
);

/// 데스크톱의 화면 · 창 목록을 받는 곳. 테스트가 바꾼다(플랫폼 구현이 없다).
final screenSourcesProvider = Provider<Future<List<ScreenSource>> Function()>(
  (_) => listScreenSources,
);

/// 통화를 붙들고 있는 곳. **화면이 아니라 뿌리에 산다**(`main.dart` 가 붙든다) — 채널을 옮겨도,
/// 설정 창에 다녀와도 통화가 끊기지 않는다(디스코드와 같다).
class VoiceSessionNotifier extends Notifier<VoiceCall?> {
  VoiceEngine? _engine;

  /// 들어가기가 겹치면(빠르게 두 채널을 누름) 늦게 끝난 쪽을 버린다.
  int _generation = 0;

  /// 권한을 잃어 화면 공유를 놓는 중 — 알림이 겹쳐도 한 번만 부른다.
  bool _droppingShare = false;

  @override
  VoiceCall? build() {
    // 로그아웃하면 통화에서도 나온다 — 다음 사람이 같은 기기에서 앞사람의 통화를 이어받지 않게.
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next is! AuthSignedIn) unawaited(leave());
    });
    ref.onDispose(() {
      _generation++;
      final engine = _engine;
      _engine = null;
      if (engine != null) unawaited(_close(engine));
    });
    return null;
  }

  Future<VoiceJoinOutcome> join({
    required String spaceId,
    required Channel channel,
  }) async {
    if (state?.channelId == channel.id) return VoiceJoinOutcome.joined;
    await leave();
    final generation = ++_generation;
    ref.read(voiceEndedProvider.notifier).clear();
    state = VoiceCall(
      spaceId: spaceId,
      channelId: channel.id,
      channelName: channel.name,
    );

    try {
      final ticket = await ref
          .read(voiceApiProvider)
          .ticket(spaceId, channel.id);
      if (generation != _generation) return VoiceJoinOutcome.superseded;
      final engine = ref.read(voiceEngineFactoryProvider)();
      _engine = engine;
      engine.addListener(_sync);
      await engine.connect(ticket.url, ticket.token);
      if (generation != _generation) return VoiceJoinOutcome.superseded;

      // 들어가면 마이크를 연다(디스코드와 같다). 읽기 전용 채널은 열 수 없는 토큰이라 묻지도 않는다.
      var outcome = VoiceJoinOutcome.joined;
      if (ticket.canSpeak) {
        try {
          await engine.setMic(true);
        } catch (_) {
          // 권한 거부 · 장치 없음은 **복구 가능한 실패**다 — 통화를 깨지 않고 듣기만 하게 둔다.
          // 사람이 권한을 고친 뒤 마이크 버튼을 다시 누르면 된다.
          outcome = VoiceJoinOutcome.micUnavailable;
        }
      }
      _sync();
      return outcome;
    } catch (_) {
      if (generation != _generation) return VoiceJoinOutcome.superseded;
      await leave();
      rethrow; // 문구는 화면이 고른다(서버 문구를 쓰지 않는다)
    }
  }

  /// 마이크를 켜고 끈다. 끌 수는 늘 있고, 켜는 것은 말할 수 있을 때만.
  Future<void> setMic(bool on) async {
    final engine = _engine;
    final call = state;
    if (engine == null || call == null) return;
    if (on && !call.canSpeak) return;
    await engine.setMic(on);
  }

  Future<void> startAudio() async => _engine?.startAudio();

  /// 화면 공유를 켜고 끈다(조각 2). 말하기와 같은 권한이다 — 읽기 전용이면 켤 수 없다(설계 V4).
  /// 고르기 창에서 사람이 취소하면 엔진이 던진다 — 부르는 쪽이 받는다.
  Future<void> setScreenShare(bool on, {String? sourceId}) async {
    final engine = _engine;
    final call = state;
    if (engine == null || call == null) return;
    if (on && !call.canSpeak) return;
    await engine.setScreenShare(on, sourceId: sourceId);
  }

  /// 그 사람이 공유 중인 화면. 통화가 없으면 빈 상자.
  Widget screenView(String userId) =>
      _engine?.screenView(userId) ?? const SizedBox.shrink();

  Future<void> leave() async {
    _generation++;
    final engine = _engine;
    _engine = null;
    state = null;
    if (engine != null) await _close(engine);
  }

  Future<void> _close(VoiceEngine engine) async {
    engine.removeListener(_sync);
    try {
      await engine.close();
    } catch (_) {
      // 나가는 중의 실패는 사람이 할 일이 없다 — 미디어 서버가 끊긴 참가자를 스스로 정리한다.
    } finally {
      engine.dispose();
    }
  }

  /// 연결의 값을 상태로 옮긴다. 끝났으면(서버가 내보냄 · 끊김) 통화를 접고 까닭을 남긴다.
  void _sync() {
    final engine = _engine;
    final call = state;
    if (engine == null || call == null) return;

    final ended = engine.ended;
    if (ended != null) {
      _generation++;
      _engine = null;
      state = null;
      unawaited(_close(engine));
      if (ended != VoiceEnd.left) {
        ref
            .read(voiceEndedProvider.notifier)
            .set(VoiceEndNotice(call.channelId, ended));
      }
      return;
    }

    // 통화 중에 읽기 전용이 되면 서버가 트랙을 내리지만 이 기기의 화면 캡처는 그대로 돈다 — 브라우저 ·
    // OS 의 「공유 중」 표시가 남고 버튼은 「공유 중지」로 남는다(웹 탐침으로 확인했다). 마이크는 SDK 가
    // 스스로 끄는데 화면 공유는 끄지 않아, 여기서 놓는다.
    if (!engine.canPublish && engine.screenShareOn && !_droppingShare) {
      _droppingShare = true;
      unawaited(
        engine
            .setScreenShare(false)
            .catchError((Object _) {})
            .whenComplete(() => _droppingShare = false),
      );
    }

    state = call.copyWith(
      link: engine.link,
      peers: engine.peers,
      micOn: engine.micOn,
      canSpeak: engine.canPublish,
      audioBlocked: engine.audioBlocked,
      screenShareOn: engine.screenShareOn,
      screenSharers: engine.screenSharers,
    );
  }
}

final voiceSessionProvider = NotifierProvider<VoiceSessionNotifier, VoiceCall?>(
  VoiceSessionNotifier.new,
);

/// 통화가 내 뜻과 달리 끝났다 — 그 채널 화면이 한 줄로 알린다. 다시 들어가면 지운다.
@immutable
class VoiceEndNotice {
  const VoiceEndNotice(this.channelId, this.reason);

  final String channelId;
  final VoiceEnd reason;
}

class VoiceEndedNotifier extends Notifier<VoiceEndNotice?> {
  @override
  VoiceEndNotice? build() => null;

  void set(VoiceEndNotice notice) => state = notice;

  void clear() => state = null;
}

final voiceEndedProvider =
    NotifierProvider<VoiceEndedNotifier, VoiceEndNotice?>(
      VoiceEndedNotifier.new,
    );
