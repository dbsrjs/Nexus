import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_storage.dart';
import '../../ui/ui.dart';
import 'settings_widgets.dart';
import 'theme_controller.dart';

/// 화면 — 테마. 예전에는 계정 메뉴에 있었다. 같은 설정이 두 곳에 있으면 어느
/// 쪽이 진짜인지 묻게 되어 이곳 하나로 옮겼다(14단계 설계 D3).
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    Widget card(String label, ThemePreference mode) => Expanded(
      child: _ThemeCard(
        label: label,
        mode: mode,
        selected: current == mode,
        onPressed: () => ref.read(themeModeProvider.notifier).set(mode),
      ),
    );

    return SettingsPage(
      title: '화면',
      children: [
        const SettingsLabel('테마'),
        // 셋 중 하나 — 보조 기술에는 라디오 무리로 읽힌다.
        Semantics(
          label: '테마',
          container: true,
          child: Row(
            children: [
              card('시스템 설정', ThemePreference.system),
              const SizedBox(width: NxSpacing.sp5),
              card('라이트', ThemePreference.light),
              const SizedBox(width: NxSpacing.sp5),
              card('다크', ThemePreference.dark),
            ],
          ),
        ),
        const SizedBox(height: NxSpacing.sp5),
        Text(
          '시스템 설정은 운영체제의 밝기를 따릅니다.',
          style: NxTheme.of(context).text.secondary,
        ),
      ],
    );
  }
}

/// 테마 하나를 미리보기와 함께 보이는 카드(캔버스 「설정」의 테마 고르기).
///
/// 미리보기의 색은 **그 테마의 토큰**이다 — 지금 테마가 다크여도 라이트 카드는
/// 라이트 바탕을 보인다.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.mode,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final ThemePreference mode;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;

    final preview = switch (mode) {
      // 시스템은 반은 라이트, 반은 다크.
      // 자식 없는 ColoredBox 는 높이가 0 이 된다 — 늘여서 칸을 채운다.
      ThemePreference.system => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ColoredBox(color: NxColors.light.bgBase)),
          Expanded(child: ColoredBox(color: NxColors.dark.bgBase)),
        ],
      ),
      ThemePreference.light => const _Swatch(tokens: NxColors.light),
      ThemePreference.dark => const _Swatch(tokens: NxColors.dark),
    };

    return NxPressable(
      onPressed: onPressed,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      semanticLabel: label,
      excludeChildSemantics: true,
      builder: (context, s) => AnimatedContainer(
        duration: NxMotion.micro,
        padding: const EdgeInsets.all(NxSpacing.inset),
        decoration: BoxDecoration(
          color: selected
              ? c.accentSubtle
              : (s.hovered ? c.bgElevated : c.bgSurface),
          borderRadius: BorderRadius.circular(NxRadius.md),
          border: Border.all(color: selected ? c.accent : c.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(NxRadius.inner),
              child: SizedBox(height: 52, child: preview),
            ),
            const SizedBox(height: NxSpacing.sp4),
            Text(
              label,
              style: nx.text.sm.copyWith(
                color: selected ? c.textPrimary : c.textSecondary,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.tokens});

  final NxColors tokens;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: tokens.bgBase,
    child: Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(NxSpacing.sp3),
        child: FractionallySizedBox(
          widthFactor: .4,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: tokens.accent,
              // 토큰 밖: 축소 미리보기 — 실제 버튼 반경(sm)을 미리보기 비율로 줄인 값.
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    ),
  );
}
