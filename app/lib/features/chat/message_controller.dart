import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/messages_api.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/socket/socket_event.dart';
import '../../domain/models/message.dart';
import '../auth/auth_controller.dart';
import '../channel/channel_controller.dart';
import '../realtime/socket_controller.dart';
import '../space/space_controller.dart';

final messagesApiProvider =
    Provider<MessagesApi>((ref) => MessagesApi(ref.watch(apiClientProvider)));

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(
    api: ref.watch(messagesApiProvider),
    db: ref.watch(appDatabaseProvider),
  );
});

/// 새로고침이 진행 중인지. 캐시를 이미 그린 뒤라 화면을 막지 않고 표시만 한다.
/// (Riverpod 3 에서 StateProvider 는 legacy 라 Notifier 를 쓴다.)
class MessagesRefreshing extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final messagesRefreshingProvider =
    NotifierProvider<MessagesRefreshing, bool>(MessagesRefreshing.new);

/// 현재 채널의 메시지.
///
/// **화면은 drift 만 구독한다** (docs/앱-설계.md §6). REST 와 소켓은 로컬 DB 를
/// 갱신할 뿐이고, 여기서는 그 결과를 흘려보낸다. 그래서 오프라인 표시와 실시간
/// 갱신이 같은 코드 경로를 탄다.
///
/// 이전 구현은 메모리 리스트를 직접 조작했다. 그때는 "REST 로 받은 것"과
/// "소켓으로 받은 것"과 "낙관적으로 넣은 것"이 각각 다른 분기를 탔고, 중복·순서
/// 문제를 그 분기마다 따로 막아야 했다.
final messagesProvider = StreamProvider<List<Message>>((ref) {
  final channelId = ref.watch(currentChannelIdProvider);
  final spaceId = ref.watch(currentSpaceIdProvider);
  if (channelId == null || spaceId == null) return Stream.value(const []);

  final repository = ref.watch(messageRepositoryProvider);

  // 캐시를 먼저 흘려보내고, 그와 별개로 서버에서 최신을 받아 온다.
  // await 하지 않는 이유: 기다리면 캐시가 있어도 첫 프레임이 늦어진다.
  _refreshInBackground(ref, repository, spaceId, channelId);
  _listenToSocket(ref, repository, spaceId, channelId);

  return repository.watch(channelId);
});

void _refreshInBackground(
  Ref ref,
  MessageRepository repository,
  String spaceId,
  String channelId,
) {
  Future.microtask(() async {
    ref.read(messagesRefreshingProvider.notifier).set(true);
    await repository.refresh(spaceId: spaceId, channelId: channelId);
    if (!ref.mounted) return;

    ref.read(messagesRefreshingProvider.notifier).set(false);
    // **채널에 들어올 때도 큐를 내보낸다.** 평소에는 소켓 재연결이 계기가
    // 되지만, 소켓이 늦거나 붙지 못하는 동안에도 대화를 열면 나가야 한다.
    // 계기가 하나뿐이면 그것이 막히는 순간 큐가 통째로 멈춘다.
    await ref.read(messageActionsProvider).flushOutbox();
    if (ref.mounted) ref.read(messageActionsProvider).markReadToLatest();
  });
}

void _listenToSocket(
  Ref ref,
  MessageRepository repository,
  String spaceId,
  String channelId,
) {
  ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (previous, next) {
    final event = next.value;
    if (event == null) return;

    switch (event) {
      case MessageNew() when event.channelId == channelId:
        // 캐시에 넣기만 하면 스트림이 알아서 화면을 갱신한다. 중복 검사도
        // 필요 없다 — 같은 id 로 upsert 하므로 결과가 같다.
        repository.applyIncoming(spaceId, event.message);
        ref.read(messageActionsProvider).markRead(event.message.id);

      case MessageEdited() when event.channelId == channelId:
        repository.applyIncoming(spaceId, event.message);

      case MessageDeleted() when event.channelId == channelId:
        repository.applyDeleted(event.messageId);

      case ThreadReply() when event.channelId == channelId:
        // 답글 본문은 스레드 화면이 받는다. 여기서는 **부모의 요약만** 고친다 —
        // 스레드를 열지 않은 사람도 "답글 3개"가 늘어나는 것은 봐야 한다.
        repository.applyThreadSummary(
          event.parentId,
          replyCount: event.replyCount,
          lastReplyAt: event.lastReplyAt,
        );

      case ReactionChanged() when event.channelId == channelId:
        // 서버는 mine 을 싣지 않는다 — 내 userId 로 여기서 접는다.
        final auth = ref.read(authControllerProvider);
        if (auth is AuthSignedIn) {
          repository.applyReactionChanged(
            event.messageId,
            event.entries,
            auth.user.id,
          );
        }

      case SocketConnected():
        // 끊겨 있는 동안 놓친 메시지를 따라잡는다.
        // (큐를 내보내는 것은 realtimeChannelSyncProvider 가 한다 — 채널을
        //  열지 않은 상태에서도 나가야 하기 때문이다.)
        repository.refresh(spaceId: spaceId, channelId: channelId);

      default:
        break;
    }
  });
}

/// 전송·재시도 같은 **동작**. 목록은 messagesProvider 가 담당한다.
final messageActionsProvider = Provider<MessageActions>((ref) => MessageActions(ref));

class MessageActions {
  MessageActions(this._ref);

  final Ref _ref;

  String? _nextCursor;
  bool _loadingOlder = false;

  MessageRepository get _repository => _ref.read(messageRepositoryProvider);

  /// 전송 = **큐에 넣고 흘려보내기.**
  ///
  /// 네트워크 상태를 묻지 않는다. 큐에 들어간 순간 화면에 보이고(캐시와 큐를
  /// 합쳐 구독하므로), 온라인이면 곧바로 나가고 오프라인이면 재연결 때 나간다.
  /// 사용자 입장에서 두 경우가 구분되지 않는 것이 목표다.
  Future<void> send(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final spaceId = _ref.read(currentSpaceIdProvider);
    final channelId = _ref.read(currentChannelIdProvider);
    if (spaceId == null || channelId == null) return;

    final auth = _ref.read(authControllerProvider);
    if (auth is! AuthSignedIn) return;

    await _repository.enqueue(
      spaceId: spaceId,
      channelId: channelId,
      body: trimmed,
      author: MessageAuthor(
        id: auth.user.id,
        name: auth.user.name,
        avatarUrl: auth.user.avatarUrl,
      ),
    );

    await flushOutbox();
  }

  /// 큐를 흘려보낸다. 재연결 시에도 불린다.
  Future<void> flushOutbox() async {
    final sent = await _repository.flush();
    if (sent > 0) markReadToLatest();
  }

  Future<void> retry(Message failed) => _repository.retry(failed.id);

  Future<void> discard(Message failed) => _repository.discard(failed.id);

  /// 리액션을 켜고 끈다. 아직 보내지 못한 메시지에는 달 수 없다 —
  /// 서버에 없는 id 로 요청하면 404 다.
  Future<void> toggleReaction(Message message, String emoji) async {
    if (message.isLocal) return;

    final spaceId = _ref.read(currentSpaceIdProvider);
    if (spaceId == null) return;

    final already =
        message.reactions.any((r) => r.emoji == emoji && r.mine);

    await _repository.toggleReaction(
      spaceId: spaceId,
      messageId: message.id,
      emoji: emoji,
      add: !already,
    );
  }

  Future<void> loadOlder() async {
    if (_loadingOlder) return;
    final spaceId = _ref.read(currentSpaceIdProvider);
    final channelId = _ref.read(currentChannelIdProvider);
    if (spaceId == null || channelId == null) return;

    // 커서가 없으면 지금 보고 있는 목록의 가장 오래된 항목부터 이어 받는다.
    final cursor = _nextCursor ?? _oldestServerMessageId();
    if (cursor == null) return;

    _loadingOlder = true;
    try {
      _nextCursor = await _repository.loadOlder(
        spaceId: spaceId,
        channelId: channelId,
        cursor: cursor,
      );
    } finally {
      _loadingOlder = false;
    }
  }

  /// 지금 보고 있는 가장 최신 메시지까지 읽은 것으로 표시한다.
  ///
  /// 아직 보내지 못한 로컬 메시지는 건너뛴다 — 서버에 없는 id 로 읽음을 저장하면
  /// 404 가 된다.
  void markReadToLatest() {
    final list = _ref.read(messagesProvider).value;
    if (list == null || list.isEmpty) return;

    for (final message in list) {
      if (!message.isLocal) {
        markRead(message.id);
        return;
      }
    }
  }

  /// 읽음 저장. 실패해도 화면에 영향이 없으므로 조용히 넘긴다 —
  /// 다음 진입에서 다시 시도된다.
  void markRead(String messageId) {
    final spaceId = _ref.read(currentSpaceIdProvider);
    final channelId = _ref.read(currentChannelIdProvider);
    if (spaceId == null || channelId == null) return;

    _ref
        .read(channelsApiProvider)
        .markRead(
          spaceId: spaceId,
          channelId: channelId,
          lastReadMessageId: messageId,
        )
        .then((_) => _ref.invalidate(channelsProvider))
        .catchError((_) {});
  }

  String? _oldestServerMessageId() {
    final list = _ref.read(messagesProvider).value;
    if (list == null || list.isEmpty) return null;
    for (final message in list.reversed) {
      if (!message.isLocal) return message.id;
    }
    return null;
  }
}
