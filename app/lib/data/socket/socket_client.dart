import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/env.dart';
import '../../domain/models/message.dart';
import '../api/api_client.dart';
import 'socket_event.dart';

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

    // 서버는 handshake.auth.token 만 받는다. 쿼리스트링 경로는 액세스 로그에
    // 토큰을 남기므로 서버에서 아예 제거됐다.
    final socket = io.io(
      Env.apiBase,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          // 끊겨도 계속 재시도한다. 모바일은 네트워크가 자주 바뀐다.
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .build(),
    );

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
      ..on('read:synced', _onReadSynced)
      ..on('rooms:invalidate', _onRoomsInvalidate);

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

  void _onRoomsInvalidate(dynamic data) {
    final map = _asMap(data);
    _emit(RoomsInvalidated(map?['reason'] as String?));
  }

  static Map<String, dynamic>? _asMap(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : null;
}

enum _MessageKind { created, edited }
