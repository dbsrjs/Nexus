import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'icons.dart';
import 'theme.dart';

/// 확인 다이얼로그(AlertDialog · showDialog 의 자리). `showGeneralDialog` 는 widgets 층이다.
///
/// 오버레이만 예외로 막을 쓴다(디자인 시스템 §4). 그림자는 없다 — 표면 한 단과 1px 선.
class NxDialog {
  NxDialog._();

  /// 확인이면 true, 취소 · 바깥 누르기 · Esc 면 false.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? body,
    String confirmLabel = '확인',
    String cancelLabel = '취소',
    bool danger = false,
  }) async {
    // 다이얼로그는 Navigator 위에 뜬다 — 부른 자리의 테마를 들고 가서 다시 깐다.
    final theme = NxTheme.of(context);
    final c = theme.colors;
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: c.scrim,
      transitionDuration: NxMotion.panel,
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: NxMotion.ease),
        child: child,
      ),
      pageBuilder: (context, _, _) => NxTheme(
        data: theme,
        child: _ConfirmPanel(
          title: title,
          body: body,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          danger: danger,
        ),
      ),
    );
    return result ?? false;
  }

  /// 제목 · 닫기 · 본문이 있는 패널(**바텀시트 · 전체 화면 다이얼로그의 자리**, 15단계 D8).
  /// 화면 가운데에 뜨고 손잡이가 없다. 좁은 화면에서는 양옆 여백만 남기고 넓어진다.
  ///
  /// 닫는 쪽이 값을 돌려주려면 `Navigator.of(context).pop(value)` — 바깥 누르기 · Esc ·
  /// 닫기 버튼은 null.
  static Future<T?> panel<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
    double width = 480,
  }) {
    final theme = NxTheme.of(context);
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: theme.colors.scrim,
      transitionDuration: NxMotion.panel,
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: NxMotion.ease),
        child: child,
      ),
      pageBuilder: (context, _, _) => NxTheme(
        data: theme,
        child: _Panel(title: title, width: width, builder: builder),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.width, required this.builder});

  final String title;
  final double width;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    final media = MediaQuery.of(context);
    void close() => Navigator.of(context).pop();

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              close();
              return null;
            },
          ),
        },
        child: Padding(
          // 키보드가 올라오면 그만큼 비킨다 — 입력 칸이 가리지 않게.
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: Center(
            child: Semantics(
              scopesRoute: true,
              explicitChildNodes: true,
              namesRoute: true,
              label: title,
              child: Container(
                width: width,
                constraints: BoxConstraints(
                  maxHeight: (media.size.height - media.viewInsets.bottom) * .85,
                ),
                margin: const EdgeInsets.all(NxSpacing.sp6),
                decoration: BoxDecoration(
                  color: c.bgElevated,
                  borderRadius: BorderRadius.circular(NxRadius.lg),
                  border: Border.all(color: c.divider),
                ),
                child: DefaultTextStyle(
                  style: theme.text.base,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          NxSpacing.sp7,
                          NxSpacing.sp5,
                          NxSpacing.sp4,
                          NxSpacing.sp5,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(title, style: theme.text.title),
                              ),
                            ),
                            NxIconButton(
                              icon: NxIcons.close,
                              label: '닫기',
                              onPressed: close,
                            ),
                          ],
                        ),
                      ),
                      Flexible(child: Builder(builder: builder)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmPanel extends StatelessWidget {
  const _ConfirmPanel({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.danger,
  });

  final String title;
  final String? body;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    void close(bool v) => Navigator.of(context).pop(v);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              close(false);
              return null;
            },
          ),
        },
        child: Center(
          child: Semantics(
            scopesRoute: true,
            explicitChildNodes: true,
            namesRoute: true,
            label: title,
            child: Container(
              width: 380,
              margin: const EdgeInsets.all(NxSpacing.sp6),
              padding: const EdgeInsets.all(NxSpacing.sp7),
              decoration: BoxDecoration(
                color: c.bgElevated,
                borderRadius: BorderRadius.circular(NxRadius.md),
                border: Border.all(color: c.divider),
              ),
              child: DefaultTextStyle(
                style: theme.text.base,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: theme.text.title),
                    if (body != null) ...[
                      const SizedBox(height: NxSpacing.sp5),
                      Text(
                        body!,
                        style: theme.text.base.copyWith(
                          color: c.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                    const SizedBox(height: NxSpacing.sp7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        NxButton(
                          label: cancelLabel,
                          kind: NxButtonKind.secondary,
                          onPressed: () => close(false),
                        ),
                        const SizedBox(width: NxSpacing.sp4),
                        NxButton(
                          label: confirmLabel,
                          autofocus: true,
                          kind: danger
                              ? NxButtonKind.danger
                              : NxButtonKind.primary,
                          onPressed: () => close(true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
