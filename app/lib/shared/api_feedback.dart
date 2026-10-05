import 'package:flutter/widgets.dart';

import '../data/api/api_failure.dart';
import '../ui/ui.dart';

/// 요청을 돌리고, 실패([ApiException])면 오류 토스트로 알린다. 성공하면 true.
///
/// 화면 아홉 곳이 같은 `try { … } on ApiException catch (e) { if (context.mounted)
/// NxToast.show(…) }` 를 들고 있었다. 문구는 서버 것이 아니라 [messageFor] 다(§3 앱 규칙).
/// `ui/` 는 `data/` 를 보지 않으므로 여기(shared)에 둔다.
Future<bool> runOrToast(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      NxToast.show(context, messageFor(e.failure), kind: NxToastKind.error);
    }
    return false;
  }
}
