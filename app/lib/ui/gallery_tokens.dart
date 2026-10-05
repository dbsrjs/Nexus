import 'package:flutter/widgets.dart';

import 'ui.dart';

/// 갤러리 맨 위의 토큰 표 — `docs/디자인-시스템.md` 와 나란히 놓고 대조한다.
///
/// 컴포넌트만 있던 갤러리에서는 «문서의 값과 코드의 값이 같은가» 를 볼 곳이 없었다
/// (2026-10-06 정비 때 반경 · 행간이 문서와 갈라져 있던 것을 그렇게 놓쳤다). 이름은 코드의
/// 이름 그대로 적는다 — 문서의 `--bg-surface` 는 `bgSurface` 다.
class NxTokenSheet extends StatelessWidget {
  const NxTokenSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    return Wrap(
      spacing: NxSpacing.sp6,
      runSpacing: NxSpacing.sp6,
      children: [
        _Group(
          title: '색 — 표면 · 글자 · 액센트',
          child: _Swatches({
            'bgBase': c.bgBase,
            'bgSurface': c.bgSurface,
            'bgElevated': c.bgElevated,
            'divider': c.divider,
            'borderStrong': c.borderStrong,
            'textPrimary': c.textPrimary,
            'textSecondary': c.textSecondary,
            'accent': c.accent,
            'accentSubtle': c.accentSubtle,
            'accentPress': c.accentPress,
          }),
        ),
        _Group(
          title: '색 — 의미 · 브랜드 · 장식',
          child: _Swatches({
            'success': c.success,
            'warning': c.warning,
            'danger': c.danger,
            'merged': c.merged,
            'onDanger': c.onDanger,
            'NxBrand.plate': NxBrand.plate,
            'NxBrand.mark': NxBrand.mark,
            'NxBrand.node': NxBrand.node,
            'decorDot': c.decorDot,
            'decorWire': c.decorWire,
            'scrim': c.scrim,
          }),
        ),
        _Group(
          title: '아바타 8색',
          child: _Swatches({
            for (var i = 0; i < c.avatars.length; i++)
              'avatars[$i]': c.avatars[i],
          }),
        ),
        _Group(
          title: '글자 — 쓰임새',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (name, style) in [
                ('heading', theme.text.heading),
                ('title', theme.text.title),
                ('header', theme.text.header),
                ('body', theme.text.body),
                ('strong', theme.text.strong),
                ('base', theme.text.base),
                ('secondary', theme.text.secondary),
                ('meta', theme.text.meta),
                ('label', theme.text.label),
                ('mono', theme.text.mono),
                ('code', theme.text.code),
                ('codeLine', theme.text.codeLine),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: NxSpacing.sp3),
                  child: Text(
                    '$name · ${style.fontSize?.toStringAsFixed(0)} — 대화 · 이슈 a3f9c21',
                    style: style,
                  ),
                ),
            ],
          ),
        ),
        _Group(
          title: '간격 (NxSpacing)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (name, v) in [
                ('sp1', NxSpacing.sp1),
                ('sp2', NxSpacing.sp2),
                ('sp3', NxSpacing.sp3),
                ('sp4', NxSpacing.sp4),
                ('inset', NxSpacing.inset),
                ('sp5', NxSpacing.sp5),
                ('sp6', NxSpacing.sp6),
                ('sp7', NxSpacing.sp7),
                ('sp8', NxSpacing.sp8),
                ('sp9', NxSpacing.sp9),
                ('sp10', NxSpacing.sp10),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: NxSpacing.sp2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: NxSpacing.sp10 + NxSpacing.sp8,
                        child: Text(
                          '$name ${v.toStringAsFixed(0)}',
                          style: theme.text.mono,
                        ),
                      ),
                      Container(
                        width: v,
                        height: NxSpacing.sp4,
                        color: c.accent,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _Group(
          title: '반경 · 투명도 · 아이콘 크기',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: NxSpacing.sp5,
                runSpacing: NxSpacing.sp5,
                children: [
                  for (final (name, r) in [
                    ('sm', NxRadius.sm),
                    ('inner', NxRadius.inner),
                    ('md', NxRadius.md),
                    ('lg', NxRadius.lg),
                    ('full', NxRadius.full),
                  ])
                    _Labeled(
                      name,
                      Container(
                        width: NxSpacing.sp10,
                        height: NxSpacing.sp9,
                        decoration: BoxDecoration(
                          color: c.bgElevated,
                          borderRadius: BorderRadius.circular(r),
                          border: Border.all(color: c.borderStrong),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: NxSpacing.sp6),
              Wrap(
                spacing: NxSpacing.sp5,
                runSpacing: NxSpacing.sp5,
                children: [
                  for (final (name, a) in [
                    ('wash', NxAlpha.wash),
                    ('tint', NxAlpha.tint),
                    ('selection', NxAlpha.selection),
                    ('edge', NxAlpha.edge),
                    ('hover', NxAlpha.hover),
                  ])
                    _Labeled(
                      name,
                      Container(
                        width: NxSpacing.sp10,
                        height: NxSpacing.sp9,
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: a),
                          borderRadius: BorderRadius.circular(NxRadius.md),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: NxSpacing.sp6),
              Row(
                children: [
                  for (final (name, s) in [
                    ('xs', NxIconSize.xs),
                    ('sm', NxIconSize.sm),
                    ('md', NxIconSize.md),
                  ]) ...[
                    _Labeled(name, NxIcon(NxIcons.settings, size: s)),
                    const SizedBox(width: NxSpacing.sp6),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    return Container(
      width: 420,
      padding: const EdgeInsets.all(NxSpacing.sp8),
      decoration: BoxDecoration(
        color: theme.colors.bgSurface,
        borderRadius: BorderRadius.circular(NxRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.text.title),
          const SizedBox(height: NxSpacing.sp6),
          child,
        ],
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches(this.colors);

  final Map<String, Color> colors;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    return Wrap(
      spacing: NxSpacing.sp4,
      runSpacing: NxSpacing.sp5,
      children: [
        for (final MapEntry(key: name, value: color) in colors.entries)
          SizedBox(
            width: NxSpacing.sp10 + NxSpacing.sp9 + NxSpacing.sp4,
            child: _Labeled(
              name,
              Container(
                height: NxSpacing.sp9,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(NxRadius.inner),
                  border: Border.all(color: theme.colors.divider),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled(this.label, this.child);

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: NxSpacing.sp2),
        Text(label, style: NxTheme.of(context).text.mono),
      ],
    );
  }
}
