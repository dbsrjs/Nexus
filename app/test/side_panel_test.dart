import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/message.dart';
import 'package:nexus_app/features/chat/message_tile.dart' show mentionsMe;
import 'package:nexus_app/features/shell/side_panel.dart';

/// 데스크톱 오른쪽 판 · 나를 부른 메시지 판정(2026-10-10 UI/UX 검토).
void main() {
  group('오른쪽 판', () {
    test('AI 판은 닫힐 때 한 번 알린다 — 다른 판으로 바뀌어도 닫힌 것이다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final panel = container.read(sidePanelProvider.notifier);

      var closed = 0;
      panel.open(
        AiSidePanel(builder: (_) => const SizedBox(), onClosed: () => closed++),
      );
      panel.open(
        const ThreadSidePanel(spaceId: 's1', channelId: 'c1', messageId: 'm1'),
      );
      expect(closed, 1);
      expect(container.read(sidePanelProvider), isA<ThreadSidePanel>());

      // 스레드 판을 닫아도 이미 닫힌 AI 판을 또 알리지 않는다.
      panel.close();
      expect(closed, 1);
      expect(container.read(sidePanelProvider), isNull);
    });

    test('같은 AI 판을 다시 열면 닫힘으로 치지 않는다 · 닫힌 판을 닫아도 조용하다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final panel = container.read(sidePanelProvider.notifier);

      var closed = 0;
      final ai = AiSidePanel(
        builder: (_) => const SizedBox(),
        onClosed: () => closed++,
      );
      panel.open(ai);
      panel.open(ai);
      expect(closed, 0);
      panel.close();
      panel.close();
      expect(closed, 1);
    });
  });

  test('컨테이너가 먼저 버려진 뒤의 closeIfAlive 는 던지지 않는다 — 앱이 내려갈 때 셸이 부른다', () {
    final container = ProviderContainer();
    final panel = container.read(sidePanelProvider.notifier);
    container.dispose();
    expect(panel.closeIfAlive, returnsNormally);
  });

  group('나를 부른 메시지', () {
    Message message({
      String authorId = 'u2',
      List<MessageMention> mentions = const [],
    }) => Message(
      id: 'm1',
      channelId: 'c1',
      body: '본문',
      createdAt: DateTime.utc(2026, 10, 10),
      author: MessageAuthor(id: authorId, name: '남'),
      mentions: mentions,
    );

    test('나를 직접 · @channel · @everyone 으로 부르면 강조한다', () {
      expect(
        mentionsMe(
          message(
            mentions: const [MessageMention(type: 'user', userId: 'me')],
          ),
          'me',
        ),
        isTrue,
      );
      expect(
        mentionsMe(
          message(mentions: const [MessageMention(type: 'channel')]),
          'me',
        ),
        isTrue,
      );
      expect(
        mentionsMe(
          message(mentions: const [MessageMention(type: 'everyone')]),
          'me',
        ),
        isTrue,
      );
    });

    test('남을 부른 것 · 내가 쓴 것 · 내 id 를 모를 때는 강조하지 않는다', () {
      expect(
        mentionsMe(
          message(
            mentions: const [MessageMention(type: 'user', userId: 'u3')],
          ),
          'me',
        ),
        isFalse,
      );
      expect(
        mentionsMe(
          message(
            authorId: 'me',
            mentions: const [MessageMention(type: 'channel')],
          ),
          'me',
        ),
        isFalse,
      );
      expect(
        mentionsMe(
          message(mentions: const [MessageMention(type: 'channel')]),
          null,
        ),
        isFalse,
      );
    });
  });
}
