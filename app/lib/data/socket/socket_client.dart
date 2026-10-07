import '../../domain/models/presence.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/env.dart';
import '../../domain/models/issue.dart';
import '../../domain/models/message.dart';
import '../../domain/models/notification_item.dart';
import '../../domain/models/space.dart';
import '../api/api_client.dart';
import 'socket_event.dart';

/// 연결 옵션. 테스트가 보도록 함수로 뺐다.
///
/// **`forceNew` 를 켠다.** socket_io_client 는 주소마다 Manager 를 캐시하고, 캐시를
/// 무시할지는 「같은 이름공간이 이미 있나」로 정한다. 그런데 API 주소에 경로가 없어
/// 그 판정이 `''` 를 찾고 소켓은 `'/'` 에 있어 늘 거짓이다 — 그래서 옛 Manager 의
/// **옛 Socket(옛 `auth`)** 이 그대로 돌아왔다. 토큰을 갱신하고 다시 붙어도 옛 토큰으로
/// 거부당해 소켓이 영영 끊겨 있었다(2026-10-07 웹 확인에서 발견, 플랫폼 공통).
@visibleForTesting
Map<String, dynamic> socketOptions(String token) => io.OptionBuilder()
    .setTransports(['websocket'])
    // 서버는 handshake.auth.token 만 받는다. 쿼리스트링 경로는 액세스 로그에
    // 토큰을 남기므로 서버에서 아예 제거됐다.
    .setAuth({'token': token})
    .disableAutoConnect()
    .enableForceNew()
    // 끊겨도 계속 재시도한다. 모바일은 네트워크가 자주 바뀐다.
    .enableReconnection()
    .setReconnectionDelay(1000)
    .setReconnectionDelayMax(10000)
    .build();

/// Socket.IO 연결 하나로 사용자의 **모든 스페이스**를 담당한다.
///
/// 서버가 연결 직후 `user:` · `space:` · `channel:` 룸에 넣어 주므로 스페이스를
/// 전환해도 재연결하지 않는다
/// (docs/superpowers/specs/2026-08-14-실시간-최소-design.md §4).
class SocketClient {
  SocketClient(this._api);

  final ApiClient _api;

  io.Socket? _socket;
  final _events = StreamController<SocketEvent>.broadcast();

  Stream<SocketEvent> get events => _events.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    final token = _api.accessToken;
    if (token == null) return;
    if (_socket != null) return;

    final socket = io.io(Env.apiBase, socketOptions(token));

    socket
      ..onConnect((_) => _emit(const SocketConnected()))
      ..onDisconnect((reason) => _emit(SocketDisconnected(reason?.toString())))
      ..onConnectError(_onConnectError)
      ..on('message:new', (data) => _emitMessage(data, _MessageKind.created))
      ..on('message:edited', (data) => _emitMessage(data, _MessageKind.edited))
      ..on('message:deleted', _onMessageDeleted)
      ..on('thread:reply', _onThreadReply)
      ..on('pin:changed', _onPinChanged)
      ..on('reaction:changed', _onReactionChanged)
      ..on('issue:created', _onIssueUpserted)
      ..on('issue:updated', _onIssueUpserted)
      ..on('issue:deleted', _onIssueDeleted)
      ..on('read:synced', _onReadSynced)
      ..on('oauth:connected', _onOauthConnected)
      ..on('ai:run:done', _onAiRunDone)
      ..on('user:updated', _onUserUpdated)
      ..on('channel:muted', _onChannelMuted)
      ..on('member:joined', (d) => _onMember(d, MemberChange.joined))
      ..on('member:updated', (d) => _onMember(d, MemberChange.updated))
      ..on('member:left', (d) => _onMember(d, MemberChange.left))
      ..on('space:removed', _onSpaceRemoved)
      ..on('space:updated', _onSpaceUpdated)
      ..on('rooms:invalidate', _onRoomsInvalidate)
      ..on('presence:changed', _onPresenceChanged)
      ..on('typing', _onTyping)
      ..on('notification:new', _onNotificationNew)
      ..on('notification:read', _onNotificationRead);

    _socket = socket;
    socket.connect();
  }

  /// 룸 재계산 요청. `rooms:invalidate` 를 받았을 때 부른다.
  void syncRooms() => _socket?.emit('rooms:sync');

  /// 읽음 위치 저장. REST `POST /read` 와 같은 코드를 지나간다.
  void markRead({
    required String spaceId,
    required String channelId,
    required String lastReadMessageId,
  }) {
    _socket?.emit('read', {
      'spaceId': spaceId,
      'channelId': channelId,
      'lastReadMessageId': lastReadMessageId,
    });
  }

  /// 이 기기의 상태(17단계 D16) — `online` · `away`.
  void setPresence(String status) => _socket?.emit('presence:set', {'status': status});

  /// 입력 중(17단계 D21). 부르는 쪽이 3초에 한 번으로 줄인다.
  void sendTyping({required String spaceId, required String channelId, String? parentId}) {
    _socket?.emit('typing', {
      'spaceId': spaceId,
      'channelId': channelId,
      'parentId': ?parentId,
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  /// 토큰이 새로 발급됐을 때. 핸드셰이크 검증은 연결 시 한 번뿐이라
  /// 새 토큰을 쓰려면 다시 연결해야 한다 (스펙 §3).
  void reconnectWithFreshToken() {
    disconnect();
    connect();
  }

  void dispose() {
    disconnect();
    _events.close();
  }

  void _emit(SocketEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  void _onConnectError(dynamic error) {
    // 미들웨어가 next(new Error('unauthorized')) 로 거부하면 여기로 온다.
    // 서버가 죽은 것과 토큰이 못 쓰게 된 것을 구분해야 앱이 재로그인을
    // 유도할지 기다릴지 정할 수 있다 (스펙 §3).
    final text = error?.toString() ?? '';
    if (text.contains('unauthorized')) {
      _emit(const SocketUnauthorized());
    } else {
      _emit(SocketDisconnected(text));
    }
  }

  void _emitMessage(dynamic data, _MessageKind kind) {
    final map = _asMap(data);
    if (map == null) return;

    final rawMessage = map['message'];
    if (rawMessage is! Map) return;

    try {
      final message =
          Message.fromJson(Map<String, dynamic>.from(rawMessage));
      final spaceId = map['spaceId'] as String? ?? '';
      final channelId = map['channelId'] as String? ?? message.channelId;

      _emit(switch (kind) {
        _MessageKind.created =>
          MessageNew(spaceId: spaceId, channelId: channelId, message: message),
        _MessageKind.edited => MessageEdited(
            spaceId: spaceId, channelId: channelId, message: message),
      });
    } catch (e) {
      // 서버가 모양을 바꿨을 때 연결 전체를 죽이지 않는다. 한 건을 버린다.
      debugPrint('소켓 메시지 파싱 실패: $e');
    }
  }

  void _onMessageDeleted(dynamic data) {
    final map = _asMap(data);
    final messageId = map?['messageId'];
    if (map == null || messageId is! String) return;
    _emit(MessageDeleted(
      spaceId: map['spaceId'] as String? ?? '',
      channelId: map['channelId'] as String? ?? '',
      messageId: messageId,
    ));
  }

  void _onThreadReply(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;

    final rawMessage = map['message'];
    final parentId = map['parentId'];
    if (rawMessage is! Map || parentId is! String) return;

    try {
      final message = Message.fromJson(Map<String, dynamic>.from(rawMessage));
      final lastReplyAt = map['lastReplyAt'];

      _emit(ThreadReply(
        spaceId: map['spaceId'] as String? ?? '',
        channelId: map['channelId'] as String? ?? message.channelId,
        parentId: parentId,
        message: message,
        replyCount: (map['replyCount'] as num?)?.toInt() ?? 0,
        lastReplyAt:
            lastReplyAt is String ? DateTime.tryParse(lastReplyAt) : null,
      ));
    } catch (e) {
      debugPrint('소켓 스레드 답글 파싱 실패: $e');
    }
  }

  /// `issue:created` 와 `issue:updated` 를 함께 받는다 — 앱이 할 일이 같다.
  /// 페이로드는 REST 응답과 같은 모양이라 파서를 따로 두지 않는다.
  void _onIssueUpserted(dynamic data) {
    final map = _asMap(data);
    final spaceId = map?['spaceId'];
    if (map == null || spaceId is! String) return;

    _emit(IssueUpserted(spaceId: spaceId, issue: Issue.fromJson(map)));
  }

  void _onIssueDeleted(dynamic data) {
    final map = _asMap(data);
    final issueId = map?['issueId'];
    if (map == null || issueId is! String) return;

    _emit(IssueDeleted(
      spaceId: map['spaceId'] as String? ?? '',
      issueId: issueId,
    ));
  }

  void _onPinChanged(dynamic data) {
    final map = _asMap(data);
    final messageId = map?['messageId'];
    if (map == null || messageId is! String) return;

    _emit(PinChanged(
      spaceId: map['spaceId'] as String? ?? '',
      channelId: map['channelId'] as String? ?? '',
      messageId: messageId,
      pinned: map['pinned'] == true,
    ));
  }

  void _onReactionChanged(dynamic data) {
    final map = _asMap(data);
    final messageId = map?['messageId'];
    if (map == null || messageId is! String) return;

    final raw = map['reactions'];
    if (raw is! List) return;

    final entries = <ReactionEntry>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final emoji = item['emoji'];
      final userId = item['userId'];
      if (emoji is String && userId is String) {
        entries.add(ReactionEntry(emoji: emoji, userId: userId));
      }
    }

    _emit(ReactionChanged(
      spaceId: map['spaceId'] as String? ?? '',
      channelId: map['channelId'] as String? ?? '',
      messageId: messageId,
      entries: entries,
    ));
  }

  void _onReadSynced(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    _emit(ReadSynced(
      spaceId: map['spaceId'] as String? ?? '',
      channelId: map['channelId'] as String? ?? '',
      lastReadMessageId: map['lastReadMessageId'] as String?,
    ));
  }

  void _onOauthConnected(dynamic data) {
    final map = _asMap(data);
    final provider = map?['provider'];
    final login = map?['login'];
    if (provider is! String || login is! String) return;

    _emit(OauthConnected(provider: provider, login: login));
  }

  void _onAiRunDone(dynamic data) {
    final map = _asMap(data);
    final runId = map?['runId'];
    if (map == null || runId is! String) return;

    _emit(AiRunDone(
      runId: runId,
      kind: map['kind'] as String? ?? 'summarize',
      state: map['state'] as String? ?? 'done',
    ));
  }

  void _onUserUpdated(dynamic data) {
    final map = _asMap(data);
    final userId = map?['userId'];
    final name = map?['name'];
    if (map == null || userId is! String || name is! String) return;
    _emit(UserUpdated(
      userId: userId,
      name: name,
      avatarUrl: map['avatarUrl'] as String?,
    ));
  }

  void _onChannelMuted(dynamic data) {
    final map = _asMap(data);
    final channelId = map?['channelId'];
    final muted = map?['muted'];
    if (map == null || channelId is! String || muted is! bool) return;
    _emit(ChannelMuted(
      spaceId: map['spaceId'] as String? ?? '',
      channelId: channelId,
      muted: muted,
    ));
  }

  void _onRoomsInvalidate(dynamic data) {
    final map = _asMap(data);
    _emit(RoomsInvalidated(map?['reason'] as String?));
  }

  void _onMember(dynamic data, MemberChange kind) {
    final map = _asMap(data);
    final spaceId = map?['spaceId'];
    final userId = map?['userId'];
    if (map == null || spaceId is! String || userId is! String) return;
    final wire = map['role'];
    _emit(MemberChanged(
      spaceId: spaceId,
      userId: userId,
      kind: kind,
      role: wire is String
          ? SpaceRole.values.where((r) => r.wire == wire).firstOrNull
          : null,
    ));
  }

  void _onSpaceUpdated(dynamic data) {
    final spaceId = _asMap(data)?['spaceId'];
    if (spaceId is! String) return;
    _emit(SpaceUpdated(spaceId));
  }

  void _onSpaceRemoved(dynamic data) {
    final spaceId = _asMap(data)?['spaceId'];
    if (spaceId is! String) return;
    _emit(SpaceRemoved(spaceId));
  }

  void _onPresenceChanged(dynamic data) {
    final map = _asMap(data);
    final userId = map?['userId'];
    if (userId is! String) return;
    _emit(PresenceChanged(userId: userId, status: presenceFromWire(map?['status'])));
  }

  void _onTyping(dynamic data) {
    final map = _asMap(data);
    final spaceId = map?['spaceId'];
    final channelId = map?['channelId'];
    final userId = map?['userId'];
    if (spaceId is! String || channelId is! String || userId is! String) return;
    final parentId = map?['parentId'];
    _emit(Typing(
      spaceId: spaceId,
      channelId: channelId,
      userId: userId,
      parentId: parentId is String ? parentId : null,
    ));
  }

  void _onNotificationNew(dynamic data) {
    final map = _asMap(data);
    final spaceId = map?['spaceId'];
    final raw = map?['notification'];
    if (spaceId is! String || raw is! Map) return;
    try {
      _emit(NotificationNew(
        spaceId: spaceId,
        notification: NotificationItem.fromJson(Map<String, dynamic>.from(raw)),
      ));
    } catch (e) {
      // 서버가 모양을 바꿨을 때 연결 전체를 죽이지 않는다. 한 건을 버린다.
      debugPrint('소켓 알림 파싱 실패: $e');
    }
  }

  void _onNotificationRead(dynamic data) {
    final map = _asMap(data);
    final spaceId = map?['spaceId'];
    if (spaceId is! String) return;
    final ids = map?['ids'];
    _emit(NotificationRead(
      spaceId: spaceId,
      ids: ids is List ? ids.whereType<String>().toList(growable: false) : null,
    ));
  }

  static Map<String, dynamic>? _asMap(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : null;
}

enum _MessageKind { created, edited }
