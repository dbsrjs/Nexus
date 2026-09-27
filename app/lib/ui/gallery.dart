import 'package:flutter/widgets.dart';

import 'ui.dart';

/// 컴포넌트 갤러리(디버그 빌드에서만 `/dev/ui`). 디자인 캔버스의 「컴포넌트 세트」와 같은
/// 배치라 둘을 나란히 놓고 대조한다. 한글 입력(IME)도 여기서 눈으로 본다.
///
/// 앱이 아직 MaterialApp 위에 있어도(15-3 전) 스스로 NxTheme · 토스트를 깐다.
class NxGallery extends StatefulWidget {
  const NxGallery({super.key});

  @override
  State<NxGallery> createState() => _NxGalleryState();
}

class _NxGalleryState extends State<NxGallery> {
  Brightness _brightness = Brightness.dark;
  bool _muted = true;
  bool _checked = true;
  String _theme = 'dark';
  String _space = 's1';
  final _name = TextEditingController(text: '이윤경');
  final _memo = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NxTheme(
      data: NxThemeData.of(_brightness),
      child: NxToastHost(
        child: Builder(
          builder: (context) {
            final theme = NxTheme.of(context);
            return ScrollConfiguration(
              behavior: const NxScrollBehavior(),
              child: NxPage(
                header: NxHeader(
                  title: '컴포넌트',
                  subtitle: 'lib/ui — Material 없음',
                  actions: [
                    NxSegmented<Brightness>(
                      label: '밝기',
                      expand: false,
                      value: _brightness,
                      segments: const [
                        (Brightness.dark, '다크'),
                        (Brightness.light, '라이트'),
                      ],
                      onChanged: (b) => setState(() => _brightness = b),
                    ),
                  ],
                ),
                body: ListView(
                  padding: const EdgeInsets.all(NxSpacing.sp8),
                  children: [
                    Wrap(
                      spacing: NxSpacing.sp6,
                      runSpacing: NxSpacing.sp6,
                      children: [
                        _Card(
                          title: 'NxButton',
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                NxButton(label: '저장', onPressed: () {}),
                                NxButton(
                                  label: '취소',
                                  kind: NxButtonKind.secondary,
                                  onPressed: () {},
                                ),
                                NxButton(
                                  label: '더 보기',
                                  kind: NxButtonKind.ghost,
                                  onPressed: () {},
                                ),
                                NxButton(
                                  label: '삭제',
                                  kind: NxButtonKind.danger,
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                const NxButton(label: '비활성', onPressed: null),
                                NxButton(
                                  label: '저장 중',
                                  loading: true,
                                  onPressed: () {},
                                ),
                                NxButton(
                                  label: '새 이슈',
                                  icon: NxIcons.plus,
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                NxButton(
                                  label: 'sm',
                                  size: NxSize.sm,
                                  onPressed: () {},
                                ),
                                const SizedBox(width: 8),
                                NxButton(label: 'md', onPressed: () {}),
                                const SizedBox(width: 8),
                                NxButton(
                                  label: 'lg',
                                  size: NxSize.lg,
                                  onPressed: () {},
                                ),
                                const SizedBox(width: 8),
                                NxIconButton(
                                  icon: NxIcons.pin,
                                  label: '고정',
                                  onPressed: () {},
                                ),
                                NxIconButton(
                                  icon: NxIcons.send,
                                  label: '보내기',
                                  filled: true,
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                        _Card(
                          title: 'NxField',
                          children: [
                            NxField(
                              label: '표시 이름',
                              controller: _name,
                              maxLength: 50,
                              helper: '다른 사람에게 보이는 이름',
                            ),
                            const NxField(
                              label: '새 비밀번호',
                              obscure: true,
                              error: '10자 이상이어야 합니다',
                            ),
                            NxField(
                              hint: '채널 · 메시지 검색',
                              dense: true,
                              leading: const NxIcon(NxIcons.search, size: 14),
                              trailing: Text('Ctrl K', style: theme.text.mono),
                            ),
                            NxField(
                              label: '여러 줄 — 한글 입력 확인',
                              controller: _memo,
                              maxLines: 4,
                              minLines: 2,
                              hint: '여기에 한글로 써 보세요',
                            ),
                          ],
                        ),
                        _Card(
                          title: '선택',
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '# 개발 — 음소거',
                                    style: theme.text.base,
                                  ),
                                ),
                                NxSwitch(
                                  value: _muted,
                                  label: '개발 음소거',
                                  onChanged: (v) => setState(() => _muted = v),
                                ),
                              ],
                            ),
                            NxCheck(
                              value: _checked,
                              label: '메시지 3개 선택',
                              onChanged: (v) => setState(() => _checked = v),
                            ),
                            NxSegmented<String>(
                              label: '테마',
                              value: _theme,
                              segments: const [
                                ('system', '시스템'),
                                ('light', '라이트'),
                                ('dark', '다크'),
                              ],
                              onChanged: (v) => setState(() => _theme = v),
                            ),
                            NxSelect<String>(
                              value: _space,
                              options: const [
                                ('s1', 'Nexus'),
                                ('s2', '사이드 프로젝트'),
                              ],
                              onChanged: (v) => setState(() => _space = v),
                            ),
                          ],
                        ),
                        _Card(
                          title: '칩 · 뱃지 · 표지',
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const NxBadge(count: 12),
                                const NxBadge(count: 2, mention: true),
                                NxTag('NEXUS-42', mono: true),
                                NxTag(
                                  'high',
                                  dot: true,
                                  color: theme.colors.warning,
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                NxChip(
                                  label: '채널 최근 대화',
                                  selected: true,
                                  onPressed: () {},
                                ),
                                NxChip(
                                  label: 'dbsrjs/Nexus',
                                  onPressed: () {},
                                  onRemove: () {},
                                ),
                                NxChip(
                                  label: '리액션',
                                  icon: NxIcons.check,
                                  trailing: '2',
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                        _Card(
                          title: '메뉴 · 툴팁 · 다이얼로그 · 토스트',
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                NxMenu(
                                  entries: [
                                    const NxMenuHeader(
                                      '이윤경',
                                      subtitle: 'yun@nexus.dev',
                                    ),
                                    const NxMenuDivider(),
                                    NxMenuItem(
                                      '설정',
                                      shortcut: 'Ctrl ,',
                                      onSelected: () {},
                                    ),
                                    NxMenuItem(
                                      '로그아웃',
                                      danger: true,
                                      onSelected: () {},
                                    ),
                                  ],
                                  anchorBuilder: (context, toggle) => NxButton(
                                    label: '계정 메뉴',
                                    kind: NxButtonKind.secondary,
                                    onPressed: toggle,
                                  ),
                                ),
                                NxTooltip(
                                  message: '고정된 메시지',
                                  child: NxIconButton(
                                    icon: NxIcons.pin,
                                    label: '고정된 메시지',
                                    onPressed: () {},
                                  ),
                                ),
                                Builder(
                                  builder: (context) => NxButton(
                                    label: '삭제 확인',
                                    kind: NxButtonKind.danger,
                                    onPressed: () => NxDialog.confirm(
                                      context,
                                      title: '메시지를 삭제할까요?',
                                      body: '본문은 가려지고 스레드와 첨부는 남습니다.',
                                      confirmLabel: '삭제',
                                      danger: true,
                                    ),
                                  ),
                                ),
                                Builder(
                                  builder: (context) => NxButton(
                                    label: '토스트 둘',
                                    kind: NxButtonKind.ghost,
                                    onPressed: () {
                                      NxToast.show(
                                        context,
                                        '이름을 바꿨습니다',
                                        kind: NxToastKind.success,
                                      );
                                      NxToast.show(
                                        context,
                                        '서버에 연결할 수 없습니다',
                                        kind: NxToastKind.error,
                                        actionLabel: '다시 시도',
                                        onAction: () {},
                                      );
                                    },
                                  ),
                                ),
                                Builder(
                                  builder: (context) => NxButton(
                                    label: '동작 카드',
                                    kind: NxButtonKind.secondary,
                                    onPressed: () {
                                      final box =
                                          context.findRenderObject()!
                                              as RenderBox;
                                      final origin = box.localToGlobal(
                                        Offset.zero,
                                      );
                                      NxActionCard.show(
                                        context,
                                        anchor: origin & box.size,
                                        entries: [
                                          NxMenuItem(
                                            '스레드로 답글',
                                            onSelected: () {},
                                          ),
                                          NxMenuItem('답장', onSelected: () {}),
                                          NxMenuItem(
                                            '이슈로 만들기',
                                            onSelected: () {},
                                          ),
                                          const NxMenuDivider(),
                                          NxMenuItem(
                                            '삭제',
                                            danger: true,
                                            onSelected: () {},
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        _Card(
                          title: '목록 · 로딩 · 아이콘',
                          children: [
                            NxRow(title: '일반', dense: true, onPressed: () {}),
                            NxRow(
                              title: '개발',
                              dense: true,
                              selected: true,
                              onPressed: () {},
                              trailing: const NxBadge(count: 1, mention: true),
                            ),
                            NxRow(
                              title: '배포',
                              dense: true,
                              onPressed: () {},
                              trailing: const NxBadge(count: 12),
                            ),
                            const NxSkeleton(lines: 3),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final i in NxIcons.values)
                                  NxIcon(
                                    i,
                                    size: 18,
                                    color: theme.colors.textPrimary,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                bottom: NxTabBar(
                  tabs: const [
                    NxTab('대화'),
                    NxTab('이슈', count: 3),
                    NxTab('저장소'),
                    NxTab('파일'),
                  ],
                  index: 0,
                  onChanged: (_) {},
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
          for (final child in children) ...[
            const SizedBox(height: NxSpacing.sp6),
            child,
          ],
        ],
      ),
    );
  }
}
