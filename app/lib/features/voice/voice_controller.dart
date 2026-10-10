import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/voice_api.dart';
import '../../data/socket/socket_event.dart';
import '../auth/auth_controller.dart';
import '../realtime/socket_controller.dart';
import '../space/space_controller.dart';

export '../../data/api/voice_api.dart';

final voiceApiProvider = Provider<VoiceApi>(
  (ref) => VoiceApi(ref.watch(apiClientProvider)),
);

/// 이 서버에 통화가 켜져 있나(20단계). 「음성 채널」 만들기를 보일지 정한다.
///
/// **모르면 꺼진 것으로 친다** — 보였다가 누르는 순간 실패하는 버튼을 만들지 않는다(§3-7).
/// 이미 있는 음성 채널은 이 값과 상관없이 목록에 보인다 — 들어가기에서 이유를 말한다.
final voiceEnabledProvider = FutureProvider<bool>((ref) async {
  try {
    return await ref.watch(voiceApiProvider).enabled();
  } catch (_) {
    return false;
  }
});

/// 음성 채널마다 지금 통화 중인 사람(`channelId` → `userId` 목록). **REST 처음 값 + 소켓.**
///
/// 프레즌스와 같은 모양이다(17-2): 저장하지 않는 휘발 상태라 drift 를 거치지 않는다. 처음 값은
/// 스페이스에 들어갈 때 · 소켓이 다시 붙을 때(끊긴 동안 놓친 것) · 볼 수 있는 채널이 바뀔 때
/// 다시 받는다. `main.dart` 가 붙든다 — 사이드바가 내려간 사이에도 이벤트를 놓치지 않게.
class VoiceRosterNotifier extends Notifier<Map<String, List<String>>> {
  @override
  Map<String, List<String>> build() {
    ref.listen<String?>(
      currentSpaceIdProvider,
      (_, id) => _load(id),
      fireImmediately: true,
    );
    ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (_, next) {
      switch (next.value) {
        case VoiceStateChanged(:final channelId, :final userIds):
          // 이벤트가 그 채널의 전체 명단이다 — 더하고 빼지 않고 통째로 바꾼다. 다른 스페이스의
          // 채널이어도 받아 둔다: 채널 id 가 열쇠라 섞이지 않는다.
          final copy = {...state};
          userIds.isEmpty ? copy.remove(channelId) : copy[channelId] = userIds;
          state = copy;
        case SocketConnected():
        case RoomsInvalidated():
        case MemberChanged():
          _load(ref.read(currentSpaceIdProvider));
        default:
          break;
      }
    });
    return const {};
  }

  Future<void> _load(String? spaceId) async {
    if (spaceId == null) return;
    try {
      final roster = await ref.read(voiceApiProvider).roster(spaceId);
      // 다른 스페이스로 옮겨 갔으면 늦게 온 값을 버린다.
      if (ref.read(currentSpaceIdProvider) != spaceId) return;
      state = roster;
    } catch (_) {
      // 모르면 아무도 없어 보일 뿐이다 — 들어가면 통화 안의 명단이 따로 보인다.
    }
  }
}

final voiceRosterProvider =
    NotifierProvider<VoiceRosterNotifier, Map<String, List<String>>>(
      VoiceRosterNotifier.new,
    );

/// 그 음성 채널에서 지금 통화 중인 사람.
final voiceRosterOfProvider = Provider.family<List<String>, String>(
  (ref, channelId) => ref.watch(
    voiceRosterProvider.select((m) => m[channelId] ?? const <String>[]),
  ),
);
