import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 메시지 다중 선택 상태.
///
/// **`chat_screen.dart` 밖에 둔다.** 그 파일이 이미 1,100줄을 넘었다.
///
/// 선택은 **한 채널 안에서만** 뜻이 있다. 채널을 옮기면 화면이
/// `clear()` 를 부른다 — 여기서 채널 id 를 들고 있지 않는 이유는, 그러면
/// 이 컨트롤러가 라우팅을 알아야 하기 때문이다.
class SelectionState {
  /// **`ids` 는 항상 불변 뷰로 감싼다.** 그냥 `Set` 을 노출하면 밖에서
  /// `.add()`/`.remove()` 로 직접 고칠 수 있어, `state =` 대입 없이 내부가
  /// 바뀌어 리스너 통지 없이 상태가 어긋난다 — 겉보기엔 안전해 보이지만
  /// 조용히 깨지는 부류라 `UnmodifiableSetView` 로 그 경로 자체를 막는다.
  SelectionState({required this.active, required Set<String> ids})
      : ids = UnmodifiableSetView(ids);

  const SelectionState.off() : active = false, ids = const {};

  final bool active;
  final Set<String> ids;

  int get count => ids.length;
}

class SelectionController extends Notifier<SelectionState> {
  @override
  SelectionState build() => const SelectionState.off();

  /// 길게 눌러 선택 모드로 들어간다.
  void start(String messageId) {
    state = SelectionState(active: true, ids: {messageId});
  }

  /// **선택 모드가 아닐 때는 아무것도 하지 않는다** — 평소의 탭이 선택으로
  /// 새지 않게 한다.
  void toggle(String messageId) {
    if (!state.active) return;

    final next = Set<String>.from(state.ids);
    if (!next.remove(messageId)) next.add(messageId);

    // 마지막 하나를 빼면 저절로 꺼진다. 빈 선택 앱바가 남으면 사용자가
    // 나가는 방법을 찾아야 한다.
    state = next.isEmpty
        ? const SelectionState.off()
        : SelectionState(active: true, ids: next);
  }

  void clear() => state = const SelectionState.off();
}

final selectionControllerProvider =
    NotifierProvider<SelectionController, SelectionState>(
  SelectionController.new,
);
