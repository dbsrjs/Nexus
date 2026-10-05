import 'package:flutter/widgets.dart';

import '../../ui/ui.dart';

/// 보낼 수 없는 채널의 입력창 자리(16단계 D27). 입력창을 꺼진 채로 두지 않고 이유를 말한다 —
/// 눌러 봐야 실패할 입력칸은 만들지 않는다(§3-7).
class ReadOnlyBar extends StatelessWidget {
  const ReadOnlyBar({super.key, this.text = '읽기 전용 채널입니다 — 리액션만 남길 수 있습니다'});

  /// 상대가 떠난 DM 은 다른 이유를 말한다(17단계 D8).
  final String text;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NxSpacing.sp7,
        vertical: NxSpacing.sp6,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Semantics(
        liveRegion: true,
        child: Text(
          text,
          style: nx.text.secondary,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
