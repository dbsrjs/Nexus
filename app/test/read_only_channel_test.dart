import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/channel.dart';
import 'package:nexus_app/domain/models/message.dart';
import 'package:nexus_app/features/channel/channel_controller.dart';
import 'package:nexus_app/features/chat/chat_screen.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/nx_host.dart';

/// 16-2 — 읽기 전용 채널(D27). 답장 · 스레드 · 고정은 감추고 리액션 · 이슈 · 선택은 남긴다.
void main() {
  final message = Message(
    id: 'm1',
    channelId: 'c1',
    body: '본문 m1',
    createdAt: DateTime.utc(2026, 10, 5, 12),
    author: const MessageAuthor(id: 'u2', name: '가영'),
  );

  Future<void> openActions(WidgetTester tester, {required bool canSend}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          channelsProvider.overrideWith(
            (ref) => Stream.value([
              Channel(id: 'c1', key: 'c1', name: '공지', canSend: canSend),
            ]),
          ),
        ],
        child: nxTestApp(
          // 앱에서는 채널 목록 · 대화 화면이 채널 목록을 늘 구독한다 — 테스트에서도 붙든다.
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(channelsProvider);
              return NxPage(body: MessageTile(message: message, grouped: false));
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.longPress(find.text('본문 m1'));
    await tester.pumpAndSettle();
  }

  testWidgets('★ 읽기 전용이면 동작 카드에 답장 · 스레드 · 고정이 없다', (tester) async {
    await openActions(tester, canSend: false);
    expect(find.text('답장'), findsNothing);
    expect(find.text('스레드로 답글'), findsNothing);
    expect(find.text('고정'), findsNothing);
    expect(find.text('이슈로 만들기'), findsOneWidget);
    expect(find.text('여러 개 선택'), findsOneWidget);
  });

  testWidgets('보낼 수 있으면 그대로 있다', (tester) async {
    await openActions(tester, canSend: true);
    expect(find.text('답장'), findsOneWidget);
    expect(find.text('스레드로 답글'), findsOneWidget);
    expect(find.text('고정'), findsOneWidget);
  });

  test('목록에 없는 채널은 보낼 수 있다고 본다 — 막는 것은 서버다', () async {
    final container = ProviderContainer(
      overrides: [channelsProvider.overrideWith((ref) => Stream.value(const <Channel>[]))],
    );
    addTearDown(container.dispose);
    container.listen(channelsProvider, (_, _) {});
    await container.read(channelsProvider.future);
    expect(container.read(channelCanSendProvider('nope')), isTrue);
  });
}
