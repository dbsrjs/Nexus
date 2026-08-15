import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/socket/socket_client.dart';
import '../../data/socket/socket_event.dart';
import '../auth/auth_controller.dart';
import '../channel/channel_controller.dart';

/// 앱 전체에 하나뿐인 소켓 연결.
///
/// 로그인 상태를 지켜본다 — 로그인하면 붙고, 로그아웃하면 끊는다. 스페이스를
/// 옮겨도 재연결하지 않는다(연결 하나가 전 스페이스를 담당한다).
final socketClientProvider = Provider<SocketClient>((ref) {
  final client = SocketClient(ref.watch(apiClientProvider));

  ref.listen<AuthState>(
    authControllerProvider,
    (previous, next) {
      if (next is AuthSignedIn) {
        client.connect();
      } else {
        client.disconnect();
      }
    },
    fireImmediately: true,
  );

  ref.onDispose(client.dispose);
  return client;
});

/// 소켓 이벤트 스트림. 화면·컨트롤러가 여기 붙는다.
final socketEventsProvider = StreamProvider<SocketEvent>((ref) {
  return ref.watch(socketClientProvider).events;
});

/// 연결 상태만 보고 싶을 때(배너 등). 이벤트를 눌러 담아 둔다.
final socketConnectedProvider = Provider<bool>((ref) {
  final event = ref.watch(socketEventsProvider).value;
  return switch (event) {
    SocketConnected() => true,
    SocketDisconnected() || SocketUnauthorized() => false,
    _ => ref.watch(socketClientProvider).isConnected,
  };
});

/// 룸 무효화·읽음 동기화처럼 **채널 목록에 영향을 주는** 이벤트를 처리한다.
///
/// 메시지 자체는 MessagesNotifier 가 받는다. 여기서는 목록·뱃지만 갱신한다.
/// `main.dart` 에서 한 번 watch 해 살려 둔다.
final realtimeChannelSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (previous, next) {
    final event = next.value;
    if (event == null) return;

    switch (event) {
      case RoomsInvalidated():
        // 서버에 룸 재계산을 요청하고, 볼 수 있는 채널이 바뀌었으니 목록도 다시 받는다.
        ref.read(socketClientProvider).syncRooms();
        ref.invalidate(channelsProvider);
        ref.invalidate(categoriesProvider);

      case SocketConnected():
        // 끊겨 있는 동안 놓친 것이 있다. 목록을 다시 받아 안 읽은 수를 맞춘다.
        // (열려 있는 채널의 메시지 catch-up 은 MessagesNotifier 가 한다.)
        //
        // **카테고리도 함께 다시 받는다.** 오프라인으로 켠 기기는 카테고리를
        // 한 번도 받지 못한 상태라, 여기서 갱신하지 않으면 서버가 돌아와도
        // 채널이 계속 '기타'에 묶여 있다 — 실기기에서 실제로 겪은 버그다.
        ref.invalidate(channelsProvider);
        ref.invalidate(categoriesProvider);

      case ReadSynced():
        // 다른 기기에서 읽었다. 뱃지를 맞춘다.
        ref.invalidate(channelsProvider);

      case MessageNew():
        // 다른 채널의 새 메시지 → 안 읽은 수가 늘었다.
        // 지금 보고 있는 채널은 MessagesNotifier 가 읽음까지 처리하므로 제외한다.
        if (event.channelId != ref.read(currentChannelIdProvider)) {
          ref.invalidate(channelsProvider);
        }

      case MessageEdited():
      case MessageDeleted():
      case SocketDisconnected():
      case SocketUnauthorized():
        break;
    }
  });
});
