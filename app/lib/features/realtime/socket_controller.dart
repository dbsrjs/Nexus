import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/socket/socket_client.dart';
import '../../data/socket/socket_event.dart';
import '../auth/auth_controller.dart';
import '../channel/channel_controller.dart';
import '../chat/message_controller.dart';
import '../issue/board_controller.dart';

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
  // 핸드셰이크 거부에 대응해 토큰을 갱신한 적이 있는지. 새 토큰으로도 거부당하면
  // 서버 쪽 문제라 계속 시도해 봐야 재사용 탐지에 걸릴 뿐이다.
  var authRetried = false;

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
        // (열려 있는 채널의 메시지 catch-up 은 messagesProvider 가 한다.)
        //
        // **카테고리도 함께 다시 받는다.** 오프라인으로 켠 기기는 카테고리를
        // 한 번도 받지 못한 상태라, 여기서 갱신하지 않으면 서버가 돌아와도
        // 채널이 계속 '기타'에 묶여 있다 — 실기기에서 실제로 겪은 버그다.
        ref.invalidate(channelsProvider);
        ref.invalidate(categoriesProvider);

        // **쌓여 있던 전송분을 내보낸다.** 여기서 하는 이유는 이 리스너가
        // 채널을 열지 않아도 살아 있기 때문이다 — 오프라인으로 여러 채널에
        // 써 두고 스페이스 화면에 머물러 있어도 재연결 시 전부 나가야 한다.
        ref.read(messageRepositoryProvider).flush();
        authRetried = false;

      case ReadSynced():
        // 다른 기기에서 읽었다. 뱃지를 맞춘다.
        ref.invalidate(channelsProvider);

      case MessageNew():
        // 다른 채널의 새 메시지 → 안 읽은 수가 늘었다.
        // 지금 보고 있는 채널은 MessagesNotifier 가 읽음까지 처리하므로 제외한다.
        if (event.channelId != ref.read(currentChannelIdProvider)) {
          ref.invalidate(channelsProvider);
        }

      case SocketUnauthorized():
        // **핸드셰이크는 연결 시점의 토큰으로 한 번만 검증된다.** 액세스 토큰이
        // 15분이라 앱을 오래 켜 두면 재연결이 계속 거부되고, 소켓이 영영 붙지
        // 않는다 — 실제로 30분 켜 둔 앱에서 겪었다. 그러면 전송 큐를 내보낼
        // 계기도 사라져 오프라인에 쓴 메시지가 나가지 못한다.
        //
        // REST 는 인터셉터가 401 을 리프레시로 처리하지만 소켓은 그 경로를
        // 지나지 않으므로 여기서 직접 갱신하고 다시 붙는다.
        if (authRetried) break;
        authRetried = true;
        ref.read(apiClientProvider).refreshAccessToken().then((ok) {
          // 실패하면 ApiClient 가 세션 만료를 알려 로그인 화면으로 간다.
          if (ok) ref.read(socketClientProvider).reconnectWithFreshToken();
        });

      case IssueUpserted():
        // 이슈는 채널에 속하지 않아 스페이스 룸으로 온다. 보드를 열어 두지
        // 않았어도 캐시를 갱신해 둔다 — 열었을 때 이미 맞아 있어야 한다.
        ref.read(issueRepositoryProvider).applyUpsert(event.spaceId, event.issue);

      case IssueDeleted():
        ref.read(issueRepositoryProvider).applyDelete(event.issueId);

      case MessageEdited():
      case MessageDeleted():
      case ReactionChanged():
      case ThreadReply():
      case PinChanged():
      case SocketDisconnected():
      case OauthConnected():
        // 채널 목록·뱃지에 영향이 없다. 리액션과 스레드 답글은 열려 있는
        // 채널·스레드의 컨트롤러가 받는다. 계정 연결은 저장소 화면이 받는다.
        break;
    }
  });
});
