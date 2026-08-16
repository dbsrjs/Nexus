import 'package:flutter/material.dart';

import '../../domain/models/space_member.dart';
import 'mention_autocomplete.dart';

/// 입력창이 **id 대신 이름을 보여 주기 위한** 컨트롤러.
///
/// 화면에 있는 글자는 `@홍길동` 이고, 서버로 나가는 본문은 `<@uuid>` 다.
/// 그 사이를 [MentionDraft] 가 잇는다 — 어디부터 어디까지가 누구인지 위치로
/// 들고 있다가 [body] 에서 되돌린다.
///
/// 길이가 같은 글자를 그대로 그리므로 커서·선택 위치가 어긋나지 않는다.
/// (보이는 글자와 다른 길이의 글자를 그리면 캐럿이 엉뚱한 자리에 선다.)
class MentionComposerController extends TextEditingController {
  MentionDraft _draft = const MentionDraft();

  MentionDraft get draft => _draft;

  /// 서버로 보낼 본문. 보이는 글자가 아니라 이 값을 보낸다.
  String get body => _draft.toBody();

  @override
  set value(TextEditingValue newValue) {
    // 사용자가 고쳤다. 멘션 위치를 따라 옮긴다.
    if (newValue.text != _draft.text) {
      _draft = _draft.withText(newValue.text);
    }
    super.value = newValue;
  }

  /// 자동완성에서 고른 멤버를 끼워 넣고 커서를 그 뒤로 옮긴다.
  void insertMention(MentionQuery query, SpaceMemberProfile member) {
    final result = _draft.insert(query, member);
    _draft = result.draft;
    // 위에서 이미 맞춰 둔 값이라 setter 를 거치지 않는다.
    super.value = TextEditingValue(
      text: result.draft.text,
      selection: TextSelection.collapsed(offset: result.cursor),
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // IME 조합 중에는 기본 구현에 맡긴다. 조합 구간 밑줄을 잃으면 한글 입력이
    // 어디까지 확정됐는지 알 수 없다 — 조합이 끝나면 곧바로 강조가 돌아온다.
    if (_draft.mentions.isEmpty ||
        _draft.text != text ||
        (withComposing && value.isComposingRangeValid)) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final highlight = style?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    final children = <TextSpan>[];
    var cursor = 0;
    for (final mention in _draft.mentions) {
      if (mention.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, mention.start)));
      }
      children.add(TextSpan(text: mention.label, style: highlight));
      cursor = mention.end;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }
    return TextSpan(style: style, children: children);
  }
}
