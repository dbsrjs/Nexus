import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/features/channel/channel_controller.dart';
import 'package:nexus_app/domain/models/message.dart';
import 'package:nexus_app/features/chat/message_composer.dart';
import 'package:nexus_app/features/chat/message_controller.dart';
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

  testWidgets('★ 쓰던 글은 그 채널에 남는다 - 채널을 옮기면 다른 대화의 입력창에 그대로 있었다', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [currentChannelProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);
    final channel = container.read(currentChannelIdProvider.notifier);
    channel.set('a');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
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
    await tester.enterText(find.byType(NxField), 'draft for a');
    await tester.pump();

    channel.set('b');
    await tester.pump();
    await tester.pump();
    expect(find.text('draft for a'), findsNothing);

    await tester.enterText(find.byType(NxField), 'draft for b');
    channel.set('a');
    await tester.pump();
    await tester.pump();
    expect(find.text('draft for a'), findsOneWidget);

    channel.set('b');
    await tester.pump();
    await tester.pump();
    expect(find.text('draft for b'), findsOneWidget);
  });

  testWidgets('★ 답장을 고르면 입력창에 초점이 간다 - 고른 뒤 입력창을 한 번 더 눌러야 했다', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [currentChannelProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
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
    final editable = find.byType(EditableText);
    expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isFalse);

    container.read(replyTargetProvider.notifier).set(
      Message(
        id: 'm1',
        channelId: 'c1',
        body: '원문',
        createdAt: DateTime.utc(2026, 10, 8),
        author: const MessageAuthor(id: 'u1', name: '나'),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
  });
}
