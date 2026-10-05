import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'text_selection.dart';
import 'theme.dart';

/// 입력칸(15단계 설계 D6). **`TextField` 가 아니라 `EditableText` 위에 직접 선다.**
///
/// 구조는 `CupertinoTextField` 와 같다 — 글자 편집은 `EditableText`, 누르기 ·
/// 끌어 선택 · 두 번 눌러 단어 선택 · 우클릭은 `TextSelectionGestureDetectorBuilder`
/// (widgets 층), 핸들과 메뉴는 자체([NxTextSelectionControls] · [NxTextContextMenu]).
/// 둘 다 widgets 층이라 Material 없이 된다.
///
/// 멘션 입력창처럼 커스텀 [TextEditingController] 를 그대로 받는다.
class NxField extends StatefulWidget {
  const NxField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.obscure = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.autofocus = false,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.style,
    this.dense = false,
    this.borderless = false,
    this.inputFormatters,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// 칸 위의 이름. 누르면 칸에 포커스가 간다.
  final String? label;

  /// 비었을 때 칸 안에 흐리게.
  final String? hint;

  /// 칸 아래 설명. [error] 가 있으면 그것이 대신한다.
  final String? helper;
  final String? error;
  final bool obscure;
  final int minLines;

  /// null 이면 끝없이 늘어난다.
  final int? maxLines;

  /// 넘게 입력되지 않고, 칸 아래에 `n/max` 를 보인다.
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool autofocus;
  final bool enabled;
  final Widget? leading;
  final Widget? trailing;
  final TextStyle? style;

  /// 32px 높이(검색 · 좁은 곳).
  final bool dense;

  /// 테두리 · 바탕 없이(채팅 입력창처럼 바깥이 틀을 그릴 때).
  final bool borderless;
  final List<TextInputFormatter>? inputFormatters;

  /// 비밀번호 관리자 · OS 자동 채우기에 알리는 뜻(`AutofillHints.username` 등).
  final Iterable<String>? autofillHints;

  @override
  State<NxField> createState() => _NxFieldState();
}

class _NxFieldState extends State<NxField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => widget.enabled;

  late final TextSelectionGestureDetectorBuilder _gestures =
      TextSelectionGestureDetectorBuilder(delegate: this);

  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  bool get _multiline => widget.maxLines == null || widget.maxLines! > 1;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    _controller.addListener(_rebuild);
    _syncFocusable();
  }

  @override
  void didUpdateWidget(NxField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_rebuild);
      _focus.addListener(_rebuild);
    }
    if (old.controller != widget.controller) {
      (old.controller ?? _ownController)?.removeListener(_rebuild);
      _controller.addListener(_rebuild);
    }
    _syncFocusable();
  }

  void _syncFocusable() {
    _focus.canRequestFocus = widget.enabled;
    if (!widget.enabled && _focus.hasFocus) _focus.unfocus();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_rebuild);
    _controller.removeListener(_rebuild);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    final focused = _focus.hasFocus;
    final hasError = widget.error != null;
    final textStyle = (widget.style ?? theme.text.base).copyWith(
      color: widget.enabled ? c.textPrimary : c.textSecondary,
    );

    final editable = EditableText(
      autofillHints: widget.autofillHints,
      key: editableTextKey,
      controller: _controller,
      focusNode: _focus,
      readOnly: !widget.enabled,
      obscureText: widget.obscure,
      obscuringCharacter: '•',
      autocorrect: !widget.obscure,
      enableSuggestions: !widget.obscure,
      autofocus: widget.autofocus,
      style: textStyle,
      strutStyle: StrutStyle.fromTextStyle(textStyle),
      cursorColor: c.accent,
      cursorWidth: 2,
      cursorRadius: const Radius.circular(1), // 토큰 밖: 커서 두께(2)의 반원
      backgroundCursorColor: c.borderStrong,
      selectionColor: c.accent.withValues(alpha: NxAlpha.selection),
      selectionControls: NxTextSelectionControls(c.accent),
      contextMenuBuilder: (context, state) => NxTextContextMenu(
        anchors: state.contextMenuAnchors,
        items: state.contextMenuButtonItems,
      ),
      minLines: _multiline ? widget.minLines : null,
      maxLines: widget.maxLines,
      keyboardType:
          widget.keyboardType ??
          (_multiline ? TextInputType.multiline : TextInputType.text),
      textInputAction:
          widget.textInputAction ??
          (_multiline ? TextInputAction.newline : TextInputAction.done),
      keyboardAppearance: theme.brightness,
      inputFormatters: [
        if (widget.maxLength != null)
          LengthLimitingTextInputFormatter(widget.maxLength),
        ...?widget.inputFormatters,
      ],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      // 누르기 · 끌기는 아래 제스처 감지기가 받는다 — TextField 와 같은 짜임이다.
      rendererIgnoresPointer: true,
      mouseCursor: SystemMouseCursors.text,
    );

    final showHint = widget.hint != null && _controller.text.isEmpty;
    final inner = Stack(
      children: [
        if (showHint)
          Positioned.fill(
            child: IgnorePointer(
              child: Text(
                widget.hint!,
                style: textStyle.copyWith(color: c.textSecondary),
                maxLines: _multiline ? null : 1,
                overflow: _multiline ? null : TextOverflow.ellipsis,
              ),
            ),
          ),
        editable,
      ],
    );

    final vertical = widget.dense ? 6.0 : (_multiline ? 8.0 : 9.0);
    final borderColor = hasError
        ? c.danger
        : focused
        ? c.accent
        : c.borderStrong;

    Widget box = Container(
      constraints: BoxConstraints(
        minHeight: widget.borderless ? 0 : (widget.dense ? 32 : 36),
      ),
      padding: widget.borderless
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(horizontal: NxSpacing.sp5, vertical: vertical),
      decoration: widget.borderless
          ? null
          : BoxDecoration(
              color: widget.enabled ? c.bgElevated : c.bgSurface,
              borderRadius: BorderRadius.circular(NxRadius.md),
              border: Border.all(
                color: widget.enabled ? borderColor : c.divider,
              ),
            ),
      child: Row(
        crossAxisAlignment: _multiline
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center,
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: NxSpacing.sp4),
          ],
          Expanded(child: inner),
          if (widget.trailing != null) ...[
            const SizedBox(width: NxSpacing.sp4),
            widget.trailing!,
          ],
        ],
      ),
    );

    // TextField 가 공짜로 주던 것 — 활성 상태와 「눌러서 입력」 동작.
    box = Semantics(
      label: widget.label ?? widget.hint,
      enabled: widget.enabled,
      onTap: widget.enabled
          ? () {
              _focus.requestFocus();
              editableTextKey.currentState?.requestKeyboard();
            }
          : null,
      child: _gestures.buildGestureDetector(
        behavior: HitTestBehavior.translucent,
        child: box,
      ),
    );

    final below = widget.error ?? widget.helper;
    final counter = widget.maxLength == null
        ? null
        : '${_controller.text.characters.length}/${widget.maxLength}';

    if (widget.label == null && below == null && counter == null) return box;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          GestureDetector(
            onTap: widget.enabled ? _focus.requestFocus : null,
            child: Padding(
              padding: const EdgeInsets.only(bottom: NxSpacing.sp3),
              child: ExcludeSemantics(
                child: Text(
                  widget.label!,
                  style: theme.text.xs.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasError
                        ? c.danger
                        : (focused ? c.accent : c.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        box,
        if (below != null || counter != null)
          Padding(
            padding: const EdgeInsets.only(top: NxSpacing.sp3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: below == null
                      ? const SizedBox()
                      : Text(
                          below,
                          style: theme.text.xs.copyWith(
                            color: hasError ? c.danger : c.textSecondary,
                          ),
                        ),
                ),
                if (counter != null) Text(counter, style: theme.text.mono),
              ],
            ),
          ),
      ],
    );
  }
}
