import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/presence_api.dart';
import '../../data/socket/socket_event.dart';
import '../../domain/models/presence.dart';
import '../auth/auth_controller.dart';
import '../realtime/socket_controller.dart';
import '../space/space_controller.dart';

export '../../domain/models/presence.dart';

final presenceApiProvider =
    Provider<PresenceApi>((ref) => PresenceApi(ref.watch(apiClientProvider)));

/// `userId` → 상태(오프라인이 아닌 사람만). **REST 처음 값 + 소켓 갱신**(D19).
///
/// 상태는 사람 단위라 스페이스를 가리지 않는다 — 서버는 함께 쓰는 스페이스의 사람 것만
/// 보내므로 섞여도 새는 것이 없다. 처음 값은 스페이스에 들어갈 때 · 소켓이 다시 붙을 때 ·
/// 멤버가 바뀔 때 다시 받는다. `main.dart` 가 붙들어 둔다(구독자가 없으면 멈춘다).
class PresenceNotifier extends Notifier<Map<String, Presence>> {
  @override
  Map<String, Presence> build() {
    ref.listen<String?>(currentSpaceIdProvider, (_, id) => _load(id), fireImmediately: true);
    ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (_, next) {
      switch (next.value) {
        case PresenceChanged(:final userId, :final status):
          final copy = {...state};
          status == Presence.offline ? copy.remove(userId) : copy[userId] = status;
          state = copy;
        case SocketConnected():
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
      final users = await ref.read(presenceApiProvider).snapshot(spaceId);
      // 다른 스페이스로 옮겨 갔으면 늦게 온 값을 버린다.
      if (ref.read(currentSpaceIdProvider) != spaceId) return;
      state = users;
    } catch (_) {
      // 모르면 모두 오프라인으로 보일 뿐이다 — 대화에 지장이 없다.
    }
  }
}

final presenceProvider =
    NotifierProvider<PresenceNotifier, Map<String, Presence>>(PresenceNotifier.new);

/// 그 사람의 상태.
final presenceOfProvider = Provider.family<Presence, String>(
  (ref, userId) => ref.watch(presenceProvider.select((m) => m[userId] ?? Presence.offline)),
);

/// 입력이 없으면 자리비움으로 치는 시간(D16).
const presenceIdleAfter = Duration(minutes: 10);

/// 이 기기의 상태를 서버에 알린다(D16) — 앱이 앞에 없거나 10분 동안 입력이 없으면 `away`.
///
/// 포인터는 `pointerRouter` 의 전역 경로로, 키는 `HardwareKeyboard` 로 듣는다 — 위젯 트리에
/// 무엇을 끼우지 않는다. 서버는 새 소켓을 온라인으로 세므로 **다시 붙을 때마다 지금 값을
/// 다시 보낸다.** `main.dart` 가 붙들어 둔다.
final presenceReporterProvider = Provider<void>((ref) {
  final reporter = _PresenceReporter(ref);
  ref.onDispose(reporter.dispose);
});

class _PresenceReporter with WidgetsBindingObserver {
  _PresenceReporter(this._ref) {
    WidgetsBinding.instance.addObserver(this);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    HardwareKeyboard.instance.addHandler(_onKey);
    _sub = _ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (_, next) {
      if (next.value is SocketConnected) _send(force: true);
    });
    _armIdle();
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<SocketEvent>> _sub;
  Timer? _idle;
  bool _foreground = true;
  bool _idleNow = false;
  String? _sent;

  void dispose() {
    _idle?.cancel();
    _sub.close();
    WidgetsBinding.instance.removeObserver(this);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    HardwareKeyboard.instance.removeHandler(_onKey);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _activity();
    _send();
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent || event is PointerHoverEvent || event is PointerScrollEvent) {
      _activity();
    }
  }

  bool _onKey(KeyEvent event) {
    _activity();
    return false; // 듣기만 한다 — 키를 삼키지 않는다.
  }

  void _activity() {
    _armIdle();
    if (_idleNow) {
      _idleNow = false;
      _send();
    }
  }

  void _armIdle() {
    _idle?.cancel();
    _idle = Timer(presenceIdleAfter, () {
      _idleNow = true;
      _send();
    });
  }

  void _send({bool force = false}) {
    final status = _foreground && !_idleNow ? 'online' : 'away';
    if (!force && status == _sent) return;
    _sent = status;
    _ref.read(socketClientProvider).setPresence(status);
  }
}
