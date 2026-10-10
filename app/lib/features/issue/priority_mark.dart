/// 우선순위 표시 — 막대 셋(1 · 2 · 3칸 채움) + 글자. 카드 · 상세가 함께 쓴다.
///
/// **색이 아니라 모양으로 가른다.** 예전에는 낮음=초록 · 보통=노랑 · 높음=빨강 점이었는데,
/// 같은 보드의 컬럼 머리가 검토=노랑 · 완료=초록이라 색이 겹쳤고 초록은 「끝났다」로
/// 읽혔다(UI 리뷰). 채운 막대 수가 높낮이를 말하고, 눈에 띄어야 하는 **높음만** 위험색을
/// 쓴다. 글자는 그대로 둔다 — 색만으로도, 모양만으로도 상태를 말하지 않는다(디자인 시스템 §6).
library;

import 'package:flutter/widgets.dart';

import '../../domain/models/issue.dart';
import '../../ui/ui.dart';
import 'board_controller.dart';

/// 채운 막대 수. 낮음 1 · 보통 2 · 높음 3.
int issuePriorityLevel(IssuePriority priority) => switch (priority) {
  IssuePriority.low => 1,
  IssuePriority.mid => 2,
  IssuePriority.high => 3,
};

/// 막대와 글자의 색 — 높음만 위험색, 나머지는 보조 글자색.
Color issuePriorityColor(NxColors c, IssuePriority priority) =>
    priority == IssuePriority.high ? c.danger : c.textSecondary;

/// 막대 셋만(글자 없이). 홀로 쓰면 의미가 전달되지 않으므로 [IssuePriorityTag] 안에서 쓴다.
class IssuePriorityBars extends StatelessWidget {
  const IssuePriorityBars({super.key, required this.priority});

  final IssuePriority priority;

  // 토큰 밖: 막대 크기는 글자(xs2) 높이에 맞춘 그림 치수다 — 간격 토큰의 역할이 아니다.
  static const double _barWidth = 3;
  static const List<double> _barHeights = [5, 8, 11];

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    final level = issuePriorityLevel(priority);
    final filled = issuePriorityColor(c, priority);

    // 글자가 곁에서 같은 뜻을 말하므로 막대는 읽어 주지 않는다.
    return ExcludeSemantics(
      child: Row(
        key: ValueKey('priority-bars-${priority.name}'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _barHeights.length; i++) ...[
            if (i > 0) const SizedBox(width: NxSpacing.sp1),
            Container(
              width: _barWidth,
              height: _barHeights[i],
              decoration: BoxDecoration(
                // 채우지 않은 칸도 자리를 지킨다 — 막대 셋이 늘 보여야 몇 칸인지 센다.
                color: i < level ? filled : c.borderStrong,
                // 토큰 밖: 3px 폭 막대의 끝 둥글림 — 가장 작은 반경 토큰(4)이 막대보다 넓다.
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 막대 + 글자(`높음`). [prefix] 를 주면 글자 앞에 붙인다(상세의 `우선순위 높음`).
class IssuePriorityTag extends StatelessWidget {
  const IssuePriorityTag({super.key, required this.priority, this.prefix = ''});

  final IssuePriority priority;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final color = issuePriorityColor(theme.colors, priority);
    // 높이 · 안쪽 여백 · 글자는 [NxTag] 와 같다 — 상태 표지와 나란히 놓여도 키가 맞는다.
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: NxSpacing.sp3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IssuePriorityBars(priority: priority),
          const SizedBox(width: NxSpacing.sp3),
          Text(
            '$prefix${issuePriorityLabel(priority)}',
            style: theme.text.xs2.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
