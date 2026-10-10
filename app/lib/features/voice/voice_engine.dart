import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

/// 통화 연결의 지금 모습.
enum VoiceLink { connecting, connected, reconnecting }

/// 통화가 끝난 까닭 — 화면이 사람에게 할 말이 다르다.
enum VoiceEnd {
  /// 내가 나왔다.
  left,

  /// 서버가 내보냈다 — 채널을 볼 수 없게 됐거나 스페이스에서 빠졌다(20단계 설계 V7).
  removed,

  /// 연결이 끊겨 다시 붙지 못했다.
  lost,
}

/// 통화 안의 한 사람. identity 는 Nexus 사용자 id 다(서버가 토큰에 그렇게 넣는다).
@immutable
class VoicePeer {
  const VoicePeer({
    required this.userId,
    required this.speaking,
    required this.micOn,
  });

  final String userId;
  final bool speaking;
  final bool micOn;

  @override
  bool operator ==(Object other) =>
      other is VoicePeer &&
      other.userId == userId &&
      other.speaking == speaking &&
      other.micOn == micOn;

  @override
  int get hashCode => Object.hash(userId, speaking, micOn);
}

/// 미디어 연결 하나. **LiveKit 을 이 뒤에 숨긴다** — 화면 · 상태는 이것만 보고, 테스트는 가짜로
/// 바꾼다(flutter_webrtc 는 테스트 환경에 플랫폼 구현이 없다).
///
/// 값이 바뀌면 알린다(`ChangeNotifier`). 한 번 쓰고 버린다 — 나왔으면 새로 만든다.
abstract class VoiceEngine extends ChangeNotifier {
  VoiceLink get link;

  /// 나를 포함한 통화 안의 사람.
  List<VoicePeer> get peers;

  bool get micOn;

  /// 지금 말할 수 있나. 통화 중에 채널이 읽기 전용이 되면 서버가 바꾸고 여기로 내려온다.
  bool get canPublish;

  /// 웹에서 브라우저가 소리 재생을 막았다 — 사람이 한 번 눌러야 풀린다(자동 재생 정책).
  bool get audioBlocked;

  /// 끝났으면 그 까닭. 아직이면 null.
  VoiceEnd? get ended;

  Future<void> connect(String url, String token);

  Future<void> setMic(bool on);

  /// [audioBlocked] 를 푸는 시도. 사람의 누름 안에서 불러야 브라우저가 받아 준다.
  Future<void> startAudio();

  /// 나오고 자원을 놓는다. 두 번 불러도 된다.
  Future<void> close();
}

/// LiveKit 으로 나르는 실제 연결.
class LiveKitVoiceEngine extends VoiceEngine {
  LiveKitVoiceEngine()
    : _room = lk.Room(
        roomOptions: const lk.RoomOptions(
          // 화면 공유를 받는 쪽이 보이는 크기만큼만 받는다 — 음성만이면 차이가 없다.
          adaptiveStream: true,
          // 아무도 받지 않는 화질 층은 보내지 않는다.
          dynacast: true,
        ),
      ) {
    _events = _room.createListener()
      ..on<lk.RoomReconnectingEvent>((_) => _setLink(VoiceLink.reconnecting))
      ..on<lk.RoomReconnectedEvent>((_) => _setLink(VoiceLink.connected))
      ..on<lk.RoomDisconnectedEvent>((e) => _onDisconnected(e.reason))
      ..on<lk.AudioPlaybackStatusChanged>((e) {
        _audioBlocked = !e.isPlaying;
        notifyListeners();
      });
    // 말하는 사람 · 마이크 · 권한 — Room 은 이벤트마다 알린다. 값을 따로 들지 않고 읽을 때 꺼낸다.
    _room.addListener(notifyListeners);
  }

  final lk.Room _room;
  late final lk.EventsListener<lk.RoomEvent> _events;
  VoiceLink _link = VoiceLink.connecting;
  VoiceEnd? _ended;
  bool _audioBlocked = false;
  bool _closed = false;

  @override
  VoiceLink get link => _link;

  @override
  VoiceEnd? get ended => _ended;

  @override
  bool get audioBlocked => _audioBlocked;

  @override
  bool get micOn => _room.localParticipant?.isMicrophoneEnabled() ?? false;

  @override
  bool get canPublish =>
      _room.localParticipant?.permissions.canPublish ?? false;

  @override
  List<VoicePeer> get peers => [
    ?_peerOf(_room.localParticipant),
    for (final p in _room.remoteParticipants.values) ?_peerOf(p),
  ];

  VoicePeer? _peerOf(lk.Participant? p) => p == null
      ? null
      : VoicePeer(
          userId: p.identity,
          speaking: p.isSpeaking,
          micOn: p.isMicrophoneEnabled(),
        );

  @override
  Future<void> connect(String url, String token) async {
    await _room.connect(url, token);
    _setLink(VoiceLink.connected);
    // 웹: 「들어가기」를 누른 그 손짓 안에서 재생을 연다. 막히면 audioBlocked 로 알린다.
    if (kIsWeb) unawaited(_room.startAudio());
  }

  @override
  Future<void> setMic(bool on) async {
    await _room.localParticipant?.setMicrophoneEnabled(on);
    notifyListeners();
  }

  @override
  Future<void> startAudio() => _room.startAudio();

  /// 닫은 뒤에는 알리지 않는다 — 들어가는 도중에 나오면 늦게 끝난 `connect` 가 여기까지 온다.
  @override
  void notifyListeners() {
    if (!_closed) super.notifyListeners();
  }

  void _setLink(VoiceLink link) {
    if (_link == link) return;
    _link = link;
    notifyListeners();
  }

  void _onDisconnected(lk.DisconnectReason? reason) {
    _ended ??= switch (reason) {
      lk.DisconnectReason.clientInitiated => VoiceEnd.left,
      lk.DisconnectReason.participantRemoved ||
      lk.DisconnectReason.roomDeleted => VoiceEnd.removed,
      _ => VoiceEnd.lost,
    };
    notifyListeners();
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _ended ??= VoiceEnd.left;
    _room.removeListener(notifyListeners);
    await _events.dispose();
    try {
      await _room.disconnect();
    } finally {
      // 마이크 트랙 · 피어 연결을 놓는다 — 놓지 않으면 데스크톱에서 마이크 표시등이 남는다.
      await _room.dispose();
    }
  }
}
