import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/socket/socket_event.dart';
import '../../domain/models/message.dart';
import '../auth/auth_controller.dart';
import '../notifications/notifications_controller.dart';
import '../realtime/socket_controller.dart';
import '../space/space_controller.dart';
import 'message_controller.dart';
import '../../core/settable.dart';

/// 지금 열려 있는 스레드의 부모 메시지 id.
///
/// 채널과 같은 방식이다 — 라우트가 진실의 원천이고 화면이 그 값을 실어 준다.
final currentThreadIdProvider =
    NotifierProvider<SettableNotifier<String?>, String?>(
      () => SettableNotifier(null),
    );

/// 스레드의 부모 메시지. 캐시에서 읽는다 — 채널을 거쳐 들어왔으면 이미 있고,
/// 없으면 `refreshThread` 가 채워 준다.
final threadParentProvider = StreamProvider<Message?>((ref) {
  final parentId = ref.watch(currentThreadIdProvider);
  if (parentId == null) return Stream.value(null);

  return ref.watch(appDatabaseProvider).watchMessage(parentId);
});

/// 답글 목록. 채널 목록과 같은 규칙으로 **최신순**이고 화면이 뒤집어 그린다.
final threadRepliesProvider = StreamProvider<List<Message>>((ref) {
  final parentId = ref.watch(currentThreadIdProvider);
  final spaceId = ref.watch(currentSpaceIdProvider);
  if (parentId == null || spaceId == null) return Stream.value(const []);

  final repository = ref.watch(messageRepositoryProvider);

  // 캐시를 먼저 흘려보내고 서버는 뒤에서 갱신한다 — 채널과 같다.
  Future.microtask(
    () => repository.refreshThread(spaceId: spaceId, parentId: parentId),
  );
  _listenToSocket(ref, parentId, spaceId);
  // 스레드를 열었다 — 그 답글 알림을 읽음으로(N12 수정). 스레드는 읽음 위치가 없어 채널을
  // 읽어도 따라오지 않았고, 읽고 답까지 한 뒤에도 알림 배지가 남았다.
  Future.microtask(() => markThreadNotificationsRead(ref, spaceId, parentId));

  return repository.watchThread(parentId);
});

/// 그 스레드 답글의 내 알림을 읽음으로. **실패를 삼킨다** — 오프라인이면 다음에 열 때 읽힌다.
/// 배지는 서버의 `notification:read` 가 내 기기 전부에서 내린다.
Future<void> markThreadNotificationsRead(
  Ref ref,
  String spaceId,
  String parentId,
) async {
  try {
    await ref.read(notificationsApiProvider).markThreadRead(spaceId, parentId);
  } catch (_) {
    // 읽음 표시를 못 해도 스레드를 읽는 데는 지장이 없다.
  }
}

/// 열려 있는 스레드에 답글이 오면 캐시에 넣는다.
///
/// 채널 화면의 답글 수 갱신은 여기서 하지 않는다 — 그쪽은 부모 행을 고쳐야
/// 하는데, 그 일은 스레드를 열지 않은 사람에게도 필요해서 별도로 처리한다.
void _listenToSocket(Ref ref, String parentId, String spaceId) {
  ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (previous, next) {
    final event = next.value;
    final repository = ref.read(messageRepositoryProvider);
    switch (event) {
      case ThreadReply() when event.parentId == parentId:
        repository.applyIncoming(spaceId, event.message);
        // 열어 둔 채 새 답글이 왔다 — 보고 있으니 그 알림도 읽힌다.
        markThreadNotificationsRead(ref, spaceId, parentId);
      // 채널 화면이 내려가 있어도(알림에서 덮어 연 스레드) 답글의 수정 · 삭제가 보이게.
      // 답글이 아닌 같은 채널의 메시지여도 캐시에 있는 행만 고치므로 해가 없다.
      case MessageEdited() when event.message.parentId == parentId:
        repository.applyEdited(event.message);
      case MessageDeleted():
        repository.applyDeleted(event.messageId);
      default:
        break;
    }
  });
}

/// 스레드 답글 전송. 채널 전송과 같은 큐를 쓰고 `parentId` 만 다르다.
final threadActionsProvider = Provider<ThreadActions>(
  (ref) => ThreadActions(ref),
);

class ThreadActions {
  ThreadActions(this._ref);

  final Ref _ref;

  Future<void> reply(
    String body, {
    List<MessageAttachment> attachments = const [],
  }) async {
    final trimmed = body.trim();
    // 답글도 첨부만 보낼 수 있다 — 채널 전송과 같은 규칙이다.
    if (trimmed.isEmpty && attachments.isEmpty) return;

    final parentId = _ref.read(currentThreadIdProvider);
    final spaceId = _ref.read(currentSpaceIdProvider);
    if (parentId == null || spaceId == null) return;

    final parent = _ref.read(threadParentProvider).value;
    if (parent == null) return;

    final auth = _ref.read(authControllerProvider);
    if (auth is! AuthSignedIn) return;

    await _ref
        .read(messageRepositoryProvider)
        .enqueue(
          spaceId: spaceId,
          channelId: parent.channelId,
          body: trimmed,
          parentId: parentId,
          attachments: attachments,
          author: MessageAuthor(
            id: auth.user.id,
            name: auth.user.name,
            avatarUrl: auth.user.avatarUrl,
          ),
        );

    await _ref.read(messageActionsProvider).flushOutbox();
  }
}
