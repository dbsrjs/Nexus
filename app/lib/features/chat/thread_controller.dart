import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/socket/socket_event.dart';
import '../../domain/models/message.dart';
import '../auth/auth_controller.dart';
import '../realtime/socket_controller.dart';
import '../space/space_controller.dart';
import 'message_controller.dart';

/// 지금 열려 있는 스레드의 부모 메시지 id.
///
/// 채널과 같은 방식이다 — 라우트가 진실의 원천이고 화면이 그 값을 실어 준다.
class CurrentThreadId extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final currentThreadIdProvider =
    NotifierProvider<CurrentThreadId, String?>(CurrentThreadId.new);

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

  return repository.watchThread(parentId);
});

/// 열려 있는 스레드에 답글이 오면 캐시에 넣는다.
///
/// 채널 화면의 답글 수 갱신은 여기서 하지 않는다 — 그쪽은 부모 행을 고쳐야
/// 하는데, 그 일은 스레드를 열지 않은 사람에게도 필요해서 별도로 처리한다.
void _listenToSocket(Ref ref, String parentId, String spaceId) {
  ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (previous, next) {
    final event = next.value;
    if (event is ThreadReply && event.parentId == parentId) {
      ref.read(messageRepositoryProvider).applyIncoming(spaceId, event.message);
    }
  });
}

/// 스레드 답글 전송. 채널 전송과 같은 큐를 쓰고 `parentId` 만 다르다.
final threadActionsProvider =
    Provider<ThreadActions>((ref) => ThreadActions(ref));

class ThreadActions {
  ThreadActions(this._ref);

  final Ref _ref;

  Future<void> reply(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final parentId = _ref.read(currentThreadIdProvider);
    final spaceId = _ref.read(currentSpaceIdProvider);
    if (parentId == null || spaceId == null) return;

    final parent = _ref.read(threadParentProvider).value;
    if (parent == null) return;

    final auth = _ref.read(authControllerProvider);
    if (auth is! AuthSignedIn) return;

    await _ref.read(messageRepositoryProvider).enqueue(
          spaceId: spaceId,
          channelId: parent.channelId,
          body: trimmed,
          parentId: parentId,
          author: MessageAuthor(
            id: auth.user.id,
            name: auth.user.name,
            avatarUrl: auth.user.avatarUrl,
          ),
        );

    await _ref.read(messageActionsProvider).flushOutbox();
  }
}
