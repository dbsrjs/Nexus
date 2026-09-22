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

/// 고른 id 를 **시간순**(오래된 것 먼저)으로 돌려준다. `newestFirst` 는 화면
/// 목록 그대로(서버가 준 최신순)의 id 다.
///
/// `Set` 은 고른(클릭한) 순서를 지킨다 — 그대로 넘기면 아래부터 위로 고른
/// 사람의 이슈 초안이 대화의 끝 메시지를 원문으로 단다(13-2 최종 검토).
/// 목록에 없는 id 는 버리지 않고 뒤에 둔다 — 조용히 빼면 서버가 404 를 줄
/// 기회를 잃는다(판단 #4).
List<String> chronologicalSelection(Set<String> selected, List<String> newestFirst) {
  final ordered = [
    for (final id in newestFirst.reversed)
      if (selected.contains(id)) id,
  ];
  return [...ordered, ...selected.where((id) => !ordered.contains(id))];
}
