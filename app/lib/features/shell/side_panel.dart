import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/ui.dart';
import '../chat/thread_screen.dart';

/// 데스크톱 셸의 오른쪽 판 — 스레드 · AI 를 대화 옆에 연다(2026-10-10 UI/UX 검토).
///
/// 예전에는 데스크톱에서도 스레드가 사이드바까지 덮는 전체 화면, AI 가 가운데 모달이었다.
/// 가장 맥락이 필요한 두 순간(답글을 달 때 · 지금 대화에 대해 물을 때)에 그 대화가 가려졌다.
/// **넓은 셸에서만** 이 판을 쓴다 — 셸이 [sidePanelAvailable] 로 알린다. 좁은 셸은 예전처럼
/// 덮어서 연다(스레드 라우트 · AI 패널 대화상자). 판단 13 「파고드는 곳은 덮어서」는 좁은
/// 폭의 규칙으로 남는다.
///
/// 라우트에 싣지 않는다. 스레드는 주소(`…/t/:id`)가 따로 있어 알림 · 링크로는 여전히 덮어
/// 열리고, 판은 지금 보는 채널에 딸린 곁가지라 채널을 옮기면 닫힌다(셸이 닫는다).
sealed class SidePanel {
  const SidePanel();
}

class ThreadSidePanel extends SidePanel {
  const ThreadSidePanel({
    required this.spaceId,
    required this.channelId,
    required this.messageId,
  });

  final String spaceId;
  final String channelId;
  final String messageId;
}

class AiSidePanel extends SidePanel {
  AiSidePanel({required this.builder, this.onClosed});

  /// 판의 내용. `close` 를 부르면 판이 닫힌다(「채널에 붙이기」 뒤처럼).
  final Widget Function(VoidCallback close) builder;

  /// 닫힐 때 한 번 — 다른 판으로 바뀌어도 닫힌 것이다. 대화상자의 `then` 자리.
  final VoidCallback? onClosed;

  /// 열 때마다 새 판 — 지난 답이 새 칩에 대한 것처럼 읽히지 않게(showAiPanel 과 같은 이유).
  final Key key = UniqueKey();
}

class SidePanelNotifier extends Notifier<SidePanel?> {
  @override
  SidePanel? build() => null;

  void open(SidePanel panel) {
    final previous = state;
    state = panel;
    if (previous is AiSidePanel && !identical(previous, panel)) {
      previous.onClosed?.call();
    }
  }

  /// 셸이 내려가며 부른다. 앱 전체가 내려가는 중이면 이 notifier 가 먼저 버려져 있다 —
  /// 그때 state 를 건드리면 던진다(앱 통합 흐름의 끝에서 잡음). 닫을 판도 없으니 그냥 둔다.
  void closeIfAlive() {
    if (ref.mounted) close();
  }

  void close() {
    final previous = state;
    if (previous == null) return;
    state = null;
    if (previous is AiSidePanel) previous.onClosed?.call();
  }
}

final sidePanelProvider = NotifierProvider<SidePanelNotifier, SidePanel?>(
  SidePanelNotifier.new,
);

/// 판이 들어갈 자리가 있는가 — 넓은 셸만 알린다. **폭을 묻지 않는다**(폭 분기는 셸 한 곳).
bool sidePanelAvailable(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<SidePanelScope>() != null;

/// 넓은 셸이 본문 둘레에 깐다. 이것이 있으면 여는 쪽이 판으로 연다.
class SidePanelScope extends InheritedWidget {
  const SidePanelScope({super.key, required super.child});

  @override
  bool updateShouldNotify(SidePanelScope old) => false;
}

/// 오른쪽 판 하나를 그린다. 넓은 셸이 본문 오른쪽에 둔다.
class SidePanelView extends ConsumerWidget {
  const SidePanelView({super.key, required this.panel});

  final SidePanel panel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void close() => ref.read(sidePanelProvider.notifier).close();

    final content = switch (panel) {
      ThreadSidePanel(:final spaceId, :final channelId, :final messageId) =>
        ThreadScreen(
          // 다른 스레드로 바꾸면 새로 만든다 — 앞 스레드의 구독 · 입력이 남지 않게.
          key: ValueKey('thread-$messageId'),
          spaceId: spaceId,
          channelId: channelId,
          messageId: messageId,
          onClose: close,
        ),
      final AiSidePanel ai => _AiFrame(
        key: ai.key,
        onClose: close,
        child: ai.builder(close),
      ),
    };

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: FocusScope(child: content),
    );
  }
}

class _AiFrame extends StatelessWidget {
  const _AiFrame({super.key, required this.onClose, required this.child});

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NxPage(
      header: NxHeader(
        title: 'AI',
        actions: [
          NxIconButton(icon: NxIcons.close, label: 'AI 닫기', onPressed: onClose),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: NxSpacing.sp6),
          child: child,
        ),
      ),
    );
  }
}
