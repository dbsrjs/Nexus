import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/features/channel/channel_controller.dart';
import 'package:nexus_app/domain/models/message.dart';
import 'package:nexus_app/domain/models/space_member.dart';
import 'package:nexus_app/features/auth/auth_controller.dart';
import 'package:nexus_app/features/chat/message_composer.dart';
import 'package:nexus_app/features/chat/message_controller.dart';
import 'package:nexus_app/features/space/members_controller.dart';
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
    final send = tester
        .getCenter(
          find.byWidgetPredicate((w) => w is NxIconButton && w.label == '보내기'),
        )
        .dy;
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

  testWidgets('★ 답장을 고르면 입력창에 초점이 간다 - 고른 뒤 입력창을 한 번 더 눌러야 했다', (tester) async {
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

    container
        .read(replyTargetProvider.notifier)
        .set(
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

  // ── 멘션 자동완성을 키보드로 (2026-10-08 웹 확인) ──
  // 후보가 떠 있어도 Enter 가 전송이라 「hi @Vi」가 반쯤 친 그대로 나갔다.

  Future<List<String>> pumpWithMembers(WidgetTester tester) async {
    final sent = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentChannelProvider.overrideWithValue(null),
          authControllerProvider.overrideWith(_SignedOut.new),
          spaceMembersProvider.overrideWith(
            (ref) async => const [
              SpaceMemberProfile(userId: 'u1', name: '가나다'),
              SpaceMemberProfile(userId: 'u2', name: '가람'),
            ],
          ),
        ],
        child: nxTestApp(
          home: NxPage(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MessageComposer(
                hint: '메시지 보내기',
                onSend: (body, _) => sent.add(body),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.showKeyboard(find.byType(NxField));
    await tester.enterText(find.byType(NxField), 'hi @가');
    await tester.pump();
    await tester.pump();
    return sent;
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).controller.text;

  testWidgets('★ 후보가 떠 있으면 Enter 는 보내지 않고 첫 후보를 고른다', (tester) async {
    final sent = await pumpWithMembers(tester);
    expect(find.text('가나다'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(sent, isEmpty);
    expect(fieldText(tester), 'hi @가나다 ');
    expect(find.text('가람'), findsNothing);

    // 고른 뒤의 Enter 는 전송이고, 본문에는 id 가 실린다.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(sent, ['hi <@u1> ']);
  });

  testWidgets('★ ↓ 로 옮긴 후보를 Tab 으로 고른다', (tester) async {
    final sent = await pumpWithMembers(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(sent, isEmpty);
    expect(fieldText(tester), 'hi @가람 ');
  });

  testWidgets('Esc 로 후보를 닫으면 Enter 는 다시 전송이다', (tester) async {
    final sent = await pumpWithMembers(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('가나다'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(sent, ['hi @가']);
  });
}

class _SignedOut extends AuthController {
  @override
  AuthState build() => const AuthSignedOut();
}
