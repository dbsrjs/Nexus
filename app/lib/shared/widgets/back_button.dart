import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../ui/ui.dart';

/// 덮어서 연 화면(저장소 · 커밋 · PR · 스레드)의 머리 줄 뒤로 가기.
///
/// 쌓인 라우트가 있으면 닫고, 없으면(주소로 바로 들어옴) [fallback] 으로 간다 —
/// AppBar 가 공짜로 주던 뒤로 가기의 자리다. 이것이 없으면 딥링크로 들어온 화면에서
/// 나갈 길이 없다.
class NxBackButton extends StatelessWidget {
  const NxBackButton({super.key, required this.fallback});

  final String fallback;

  @override
  Widget build(BuildContext context) => NxIconButton(
    icon: NxIcons.back,
    label: '뒤로',
    onPressed: () =>
        context.canPop() ? context.pop() : context.go(fallback),
  );
}
