import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/features/channel/channel_controller.dart';
import 'package:nexus_app/features/chat/message_composer.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/nx_host.dart';

/// 입력창 한 판(첨부 · 입력 · 보내기)의 정렬.
void main() {
  testWidgets('★ 한 줄일 때 입력 글자의 가운데가 보내기 버튼 가운데와 맞는다 - 4px 처졌었다', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentChannelProvider.overrideWithValue(null)],
        child: nxTestApp(
          home: NxPage(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MessageComposer(hint: '메시지 보내기', onSend: (_, _) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final hint = tester.getCenter(find.text('메시지 보내기')).dy;
    final send = tester.getCenter(
      find.byWidgetPredicate((w) => w is NxIconButton && w.label == '보내기'),
    ).dy;
    expect((hint - send).abs(), lessThanOrEqualTo(1));
  });
}
