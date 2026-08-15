import 'dart:math';

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
    if (ref.mounted) {
      ref.read(messagesRefreshingProvider.notifier).set(false);
      ref.read(messageActionsProvider).markReadToLatest();
    }
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

      case SocketConnected():
        // 끊겨 있는 동안 놓친 메시지를 따라잡는다.
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

  /// 낙관적 전송.
  ///
  /// 서버 응답을 기다리지 않고 캐시에 먼저 넣는다. 실패하면 지우지 않고
  /// failed 로 남긴다 — 조용히 사라지면 사용자는 보냈다고 믿는다.
  /// **캐시에 남으므로 앱을 껐다 켜도 재시도할 수 있다.**
  Future<void> send(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final spaceId = _ref.read(currentSpaceIdProvider);
    final channelId = _ref.read(currentChannelIdProvider);
    if (spaceId == null || channelId == null) return;

    final auth = _ref.read(authControllerProvider);
    if (auth is! AuthSignedIn) return;

    final localId = _localId();
    final optimistic = Message(
      id: localId,
      channelId: channelId,
      body: trimmed,
      createdAt: DateTime.now(),
      author: MessageAuthor(
        id: auth.user.id,
        name: auth.user.name,
        avatarUrl: auth.user.avatarUrl,
      ),
      pending: true,
    );

    await _repository.insertPending(spaceId, optimistic);

    try {
      final sent = await _ref.read(messagesApiProvider).send(
            spaceId: spaceId,
            channelId: channelId,
            body: trimmed,
          );
      await _repository.settleSent(spaceId, localId, sent);
      markRead(sent.id);
    } catch (_) {
      await _repository.markFailed(spaceId, optimistic);
    }
  }

  Future<void> retry(Message failed) async {
    await _repository.discard(failed.id);
    await send(failed.body);
  }

  Future<void> discard(Message failed) => _repository.discard(failed.id);

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

  static String _localId() =>
      'local-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
}
