import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../data/api/messages_api.dart';
import '../../data/socket/socket_event.dart';
import '../../domain/models/message.dart';
import '../auth/auth_controller.dart';
import '../channel/channel_controller.dart';
import '../realtime/socket_controller.dart';
import '../space/space_controller.dart';

final messagesApiProvider =
    Provider<MessagesApi>((ref) => MessagesApi(ref.watch(apiClientProvider)));

/// 현재 채널의 메시지.
///
/// 채널마다 provider 를 만들지 않고(family) **현재 채널 하나만** 들고 있는다.
/// 화면에 열리는 채널은 언제나 하나뿐이고, 여러 채널의 메시지를 메모리에
/// 쌓아 두는 것은 6단계의 drift 캐시가 할 일이다.
///
/// 목록은 서버가 주는 그대로 **최신순**이다. 화면은 reverse ListView 라
/// 뒤집지 않는다 — 뒤집으면 페이지를 이어붙일 때마다 다시 뒤집어야 한다.
class MessagesNotifier extends AsyncNotifier<List<Message>> {
  String? _nextCursor;
  bool _loadingMore = false;

  bool get hasMore => _nextCursor != null;

  @override
  Future<List<Message>> build() async {
    final spaceId = ref.watch(currentSpaceIdProvider);
    final channelId = ref.watch(currentChannelIdProvider);
    if (spaceId == null || channelId == null) return const [];

    _listenToSocket(spaceId, channelId);

    final page = await ref.watch(messagesApiProvider).list(
          spaceId: spaceId,
          channelId: channelId,
        );
    _nextCursor = page.nextCursor;

    // 채널을 열었으면 읽은 것이다. 실패해도 화면을 막지 않는다.
    if (page.items.isNotEmpty) {
      _markRead(spaceId, channelId, page.items.first.id);
    }

    return page.items;
  }

  /// 실시간 반영.
  ///
  /// **지금 보고 있는 채널의 이벤트만** 처리한다. 다른 채널의 메시지는
  /// 안 읽은 수만 바뀌면 되고 그것은 realtimeChannelSyncProvider 가 맡는다.
  void _listenToSocket(String spaceId, String channelId) {
    ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (previous, next) {
      final event = next.value;
      if (event == null) return;

      switch (event) {
        case MessageNew() when event.channelId == channelId:
          _insertFromServer(event.message);
          // 보고 있는 채널이므로 읽은 것으로 친다.
          _markRead(spaceId, channelId, event.message.id);

        case MessageEdited() when event.channelId == channelId:
          _replace(event.message.id, event.message);

        case MessageDeleted() when event.channelId == channelId:
          _applyDeleted(event.messageId);

        case SocketConnected():
          // 끊겨 있는 동안 놓친 메시지가 있다. 첫 페이지를 다시 받아 맞춘다.
          // 커서를 이어 받는 대신 통째로 다시 받는 이유는, 놓친 구간의 길이를
          // 알 수 없고 첫 페이지 재조회가 가장 단순하기 때문이다.
          _catchUp(spaceId, channelId);

        default:
          break;
      }
    });
  }

  /// 서버가 브로드캐스트한 메시지를 목록에 넣는다.
  ///
  /// **내가 보낸 메시지도 나에게 돌아온다.** 이미 있는 id 면 무시해 중복을 막는다.
  /// 낙관적 항목(로컬 id)은 HTTP 응답이 오면 정리되므로 여기서 건드리지 않는다.
  void _insertFromServer(Message message) {
    final list = state.value;
    if (list == null) return;
    if (list.any((m) => m.id == message.id)) return;

    state = AsyncData([message, ...list]);
  }

  void _applyDeleted(String messageId) {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([
      for (final m in list)
        if (m.id == messageId)
          m.copyWith(deletedAt: m.deletedAt ?? DateTime.now(), body: '')
        else
          m,
    ]);
  }

  Future<void> _catchUp(String spaceId, String channelId) async {
    try {
      final page = await ref
          .read(messagesApiProvider)
          .list(spaceId: spaceId, channelId: channelId);
      _nextCursor = page.nextCursor;

      // 아직 서버에 닿지 못한 로컬 항목(전송 중·실패)은 살려 둔다.
      final pendingLocal =
          (state.value ?? const <Message>[]).where((m) => m.isLocal).toList();
      state = AsyncData([...pendingLocal, ...page.items]);
    } on ApiException {
      // 재연결 직후 서버가 아직 준비되지 않았을 수 있다. 보고 있던 목록을 유지한다.
    }
  }

  /// 위로 스크롤했을 때 다음 페이지. 커서는 마지막(가장 오래된) 항목의 id 다.
  Future<void> loadMore() async {
    if (_loadingMore || _nextCursor == null) return;
    final spaceId = ref.read(currentSpaceIdProvider);
    final channelId = ref.read(currentChannelIdProvider);
    if (spaceId == null || channelId == null) return;

    _loadingMore = true;
    try {
      final page = await ref.read(messagesApiProvider).list(
            spaceId: spaceId,
            channelId: channelId,
            cursor: _nextCursor,
          );
      _nextCursor = page.nextCursor;
      state = AsyncData([...(state.value ?? const []), ...page.items]);
    } on ApiException {
      // 다음 페이지를 못 가져와도 이미 보고 있는 목록은 유지한다.
    } finally {
      _loadingMore = false;
    }
  }

  /// 낙관적 전송.
  ///
  /// 서버 응답을 기다리지 않고 먼저 그린다. 채팅에서 입력 후 몇백 ms 동안
  /// 아무 일도 일어나지 않으면 느리게 느껴지기 때문이다.
  /// 실패하면 지우지 않고 **failed 로 표시**해 재시도할 수 있게 남긴다 —
  /// 조용히 사라지면 사용자는 보냈다고 믿는다.
  Future<void> send(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final spaceId = ref.read(currentSpaceIdProvider);
    final channelId = ref.read(currentChannelIdProvider);
    if (spaceId == null || channelId == null) return;

    final me = ref.read(authControllerProvider);
    if (me is! AuthSignedIn) return;

    final localId = _localId();
    final optimistic = Message(
      id: localId,
      channelId: channelId,
      body: trimmed,
      createdAt: DateTime.now(),
      author: MessageAuthor(
        id: me.user.id,
        name: me.user.name,
        avatarUrl: me.user.avatarUrl,
      ),
      pending: true,
    );

    state = AsyncData([optimistic, ...(state.value ?? const [])]);

    try {
      final sent = await ref.read(messagesApiProvider).send(
            spaceId: spaceId,
            channelId: channelId,
            body: trimmed,
          );
      _settleSent(localId, sent);
      // 내가 보낸 메시지까지 읽은 것으로 친다.
      _markRead(spaceId, channelId, sent.id);
    } on ApiException {
      _replace(localId, optimistic.copyWith(pending: false, failed: true));
    }
  }

  /// 실패한 메시지 재시도 — 지우고 같은 본문으로 다시 보낸다.
  Future<void> retry(Message failedMessage) async {
    _remove(failedMessage.id);
    await send(failedMessage.body);
  }

  /// 실패한 메시지 버리기.
  void discard(Message failedMessage) => _remove(failedMessage.id);

  /// 낙관적 항목을 서버가 준 메시지로 확정한다.
  ///
  /// **소켓 브로드캐스트가 HTTP 응답보다 먼저 도착할 수 있다.** 그 경우 목록에는
  /// 이미 실제 메시지가 들어 있으므로, 자리를 바꾸는 대신 로컬 항목만 지운다.
  /// 그러지 않으면 같은 메시지가 두 번 보인다.
  void _settleSent(String localId, Message sent) {
    final list = state.value;
    if (list == null) return;

    if (list.any((m) => m.id == sent.id)) {
      _remove(localId);
      return;
    }
    _replace(localId, sent);
  }

  void _replace(String id, Message next) {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([
      for (final m in list)
        if (m.id == id) next else m,
    ]);
  }

  void _remove(String id) {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([
      for (final m in list)
        if (m.id != id) m,
    ]);
  }

  void _markRead(String spaceId, String channelId, String messageId) {
    ref
        .read(channelsApiProvider)
        .markRead(
          spaceId: spaceId,
          channelId: channelId,
          lastReadMessageId: messageId,
        )
        // 안 읽은 수 뱃지를 즉시 반영한다.
        .then((_) => ref.invalidate(channelsProvider))
        .catchError((_) {
      // 읽음 저장은 실패해도 화면에 영향이 없다. 다음 진입에서 다시 시도된다.
    });
  }

  static String _localId() {
    final rand = Random();
    return 'local-${DateTime.now().microsecondsSinceEpoch}-${rand.nextInt(1 << 32)}';
  }
}

final messagesProvider =
    AsyncNotifierProvider<MessagesNotifier, List<Message>>(MessagesNotifier.new);
