import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/message.dart';
import 'package:nexus_app/features/chat/chat_screen.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/nx_host.dart';

/// 메시지 한 줄의 짜임.
void main() {
  const author = MessageAuthor(id: 'u1', name: '나');

  Message message(String id, {DateTime? deletedAt}) => Message(
    id: id,
    channelId: 'c1',
    body: '본문 $id',
    createdAt: DateTime.utc(2026, 9, 28, 12),
    author: author,
    deletedAt: deletedAt,
  );

  testWidgets('★ 삭제된 메시지 문구는 다른 메시지의 본문 칸에 맞춰 선다 - 맨 왼쪽에 붙었었다', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: nxTestApp(
          home: NxPage(
            body: Column(
              children: [
                MessageTile(message: message('m1'), grouped: false),
                MessageTile(
                  message: message('m2', deletedAt: DateTime.utc(2026, 9, 28, 13)),
                  grouped: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final body = tester.getTopLeft(find.text('본문 m1')).dx;
    final deleted = tester.getTopLeft(find.text('삭제된 메시지입니다.')).dx;
    expect(deleted, body);
  });

  testWidgets('★ 스레드 뿌리로 그릴 때는 「답글 N개」를 감춘다 - 같은 스레드가 한 겹 더 열렸다', (
    tester,
  ) async {
    final root = message('m1').copyWith(replyCount: 2);
    Future<void> pump({required bool summary}) => tester.pumpWidget(
      ProviderScope(
        child: nxTestApp(
          home: NxPage(
            body: MessageTile(
              message: root,
              grouped: false,
              showThreadSummary: summary,
            ),
          ),
        ),
      ),
    );

    await pump(summary: true);
    expect(find.text('답글 2개'), findsOneWidget);
    await pump(summary: false);
    expect(find.text('답글 2개'), findsNothing);
  });
}
