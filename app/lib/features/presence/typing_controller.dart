import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/socket/socket_event.dart';
import '../auth/auth_controller.dart';
import '../realtime/socket_controller.dart';

/// 「입력 중」을 얼마나 붙들어 두나(17단계 D23). 앱은 3초에 한 번 보내므로 두 번을 놓쳐야 지운다.
const typingShownFor = Duration(seconds: 6);

/// 입력 중일 때 서버에 알리는 간격(D21).
const typingSendEvery = Duration(seconds: 3);

/// 채널 또는 스레드 하나를 가리키는 열쇠. 스레드는 `parentId` 가 같은 것만 모인다(D24).
String typingKey(String channelId, String? parentId) => '$channelId|${parentId ?? ''}';

/// 열쇠 → (userId → 사라질 시각). 저장하지 않는 휘발 상태다.
///
/// 지우는 때는 둘 — 6초가 지나거나, **그 사람의 새 메시지가 오거나**(D23). 별도의 「멈춤」
/// 이벤트는 없다. `main.dart` 가 붙들어 둔다 — 채널을 열기 전에 온 것도 놓치지 않게.
class TypingNotifier extends Notifier<Map<String, Map<String, DateTime>>> {
  Timer? _sweep;

  @override
  Map<String, Map<String, DateTime>> build() {
    ref.onDispose(() => _sweep?.cancel());
    ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (_, next) {
      final event = next.value;
      switch (event) {
        case Typing():
          if (event.userId == _myId()) return;
          _put(typingKey(event.channelId, event.parentId), event.userId);
        case MessageNew():
          _drop(typingKey(event.channelId, null), event.message.author.id);
        case ThreadReply():
          _drop(typingKey(event.channelId, event.parentId), event.message.author.id);
        default:
          break;
      }
    });
    return const {};
  }

  String? _myId() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthSignedIn ? auth.user.id : null;
  }

  void _put(String key, String userId) {
    final until = DateTime.now().add(typingShownFor);
    state = {
      ...state,
      key: {...?state[key], userId: until},
    };
    _schedule();
  }

  void _drop(String key, String userId) {
    final users = state[key];
    if (users == null || !users.containsKey(userId)) return;
    state = {...state, key: {...users}..remove(userId)};
  }

  /// 가장 먼저 사라질 것에 맞춰 한 번 깨어난다.
  void _schedule() {
    _sweep?.cancel();
    DateTime? next;
    for (final users in state.values) {
      for (final until in users.values) {
        if (next == null || until.isBefore(next)) next = until;
      }
    }
    if (next == null) return;
    _sweep = Timer(next.difference(DateTime.now()) + const Duration(milliseconds: 50), () {
      final now = DateTime.now();
      state = {
        for (final e in state.entries)
          e.key: {
            for (final u in e.value.entries)
              if (u.value.isAfter(now)) u.key: u.value,
          },
      };
      _schedule();
    });
  }
}

final typingProvider =
    NotifierProvider<TypingNotifier, Map<String, Map<String, DateTime>>>(TypingNotifier.new);

/// 그 채널(또는 스레드)에서 지금 입력 중인 사람들 — 먼저 시작한 순서.
final typingUsersProvider = Provider.family<List<String>, String>((ref, key) {
  final users = ref.watch(typingProvider.select((m) => m[key]));
  return users == null ? const [] : users.keys.toList(growable: false);
});

/// 입력창 위 한 줄의 문구(D24). 아무도 없으면 null.
String? typingLabel(List<String> names) => switch (names.length) {
      0 => null,
      1 => '${names[0]} 님이 입력 중…',
      2 => '${names[0]}, ${names[1]} 님이 입력 중…',
      _ => '여러 명이 입력 중…',
    };
