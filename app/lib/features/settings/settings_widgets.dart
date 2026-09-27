import 'package:flutter/widgets.dart';

import '../../ui/ui.dart';

/// 설정 섹션 한 장. 제목과 본문을 같은 폭 · 같은 간격으로 그린다.
///
/// **자기 폭을 모른다** — 두 단이든 한 단이든 받은 자리 안에서 최대 720px 로
/// 가운데가 아니라 왼쪽에 붙는다(디스코드 · 캔버스 「설정」). 폭 분기는 `SettingsFrame` 몫이다.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return ListView(
      padding: SettingsInsets.of(context),
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: nx.text.heading),
                ),
                const SizedBox(height: NxSpacing.sp9),
                ...children,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 섹션 본문의 여백. **폭을 보고 정하는 것은 `SettingsFrame`(app_shell.dart)** 이고 여기는
/// 받은 값을 쓸 뿐이다 — 폭 분기를 한 파일에 두는 규칙(CLAUDE.md §3 앱 규칙).
class SettingsInsets extends InheritedWidget {
  const SettingsInsets({super.key, required this.insets, required super.child});

  /// 넓은 화면의 기본값(캔버스 「설정」 40 · 48).
  static const wide = EdgeInsets.fromLTRB(48, 40, 48, 48);

  final EdgeInsets insets;

  static EdgeInsets of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsInsets>()?.insets ?? wide;

  @override
  bool updateShouldNotify(SettingsInsets old) => old.insets != insets;
}

/// 섹션 안의 소제목(12px · 굵게 · 보조 글자색).
class SettingsLabel extends StatelessWidget {
  const SettingsLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: NxSpacing.sp5),
    child: Text(
      text,
      style: NxTheme.of(context).text.meta.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

/// 섹션 사이 구분(위아래 32px).
class SettingsGap extends StatelessWidget {
  const SettingsGap({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: NxSpacing.sp9),
    child: NxDivider(),
  );
}

/// 실패 한 줄. **성공은 토스트로 알리고**(캔버스 「설정」), 실패는 고칠 자리 곁에 남긴다 —
/// 토스트는 사라지지만 무엇이 틀렸는지는 고칠 때까지 보여야 한다.
class SettingsError extends StatelessWidget {
  const SettingsError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: NxSpacing.sp4),
      child: Semantics(
        liveRegion: true,
        child: Text(
          text,
          style: nx.text.secondary.copyWith(color: nx.colors.danger),
        ),
      ),
    );
  }
}
