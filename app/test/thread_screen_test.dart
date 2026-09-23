import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/domain/models/channel.dart';
import 'package:nexus_app/domain/models/message.dart';
import 'package:nexus_app/features/channel/channel_controller.dart';
import 'package:nexus_app/features/chat/thread_controller.dart';
import 'package:nexus_app/features/chat/thread_screen.dart';
import 'package:nexus_app/features/space/space_controller.dart';

/// 스레드 화면의 수명.
///
/// 닫힐 때 `dispose()` 가 context 로 조상을 찾으면 디버그 빌드에서
/// "deactivated widget's ancestor" 로 죽는다 — 디버거가 붙어 있으면 앱이 멈춘다.
/// 캐시 · 소켓은 이 검사와 무관하므로 두 스트림은 비워서 갈아 끼운다.
void main() {
  testWidgets('★ 스레드를 닫아도 예외가 나지 않고 열린 스레드 id 를 비운다', (tester) async {
    final container = ProviderContainer(
      overrides: [
        // 파일 DB 를 열면 drift 가 타이머를 남겨 테스트가 끝나지 않는다.
        appDatabaseProvider.overrideWith((ref) {
          final db = AppDatabase(NativeDatabase.memory());
          ref.onDispose(db.close);
          return db;
        }),
        // 스페이스 id 가 실리면 채널 목록이 서버를 부른다. 이 검사에는 필요 없다.
        channelsProvider.overrideWith(
          (ref) => Stream<List<Channel>>.value(const []),
        ),
        threadParentProvider.overrideWith(
          (ref) => Stream<Message?>.value(null),
        ),
        threadRepliesProvider.overrideWith(
          (ref) => Stream<List<Message>>.value(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ThreadScreen(spaceId: 's1', channelId: 'c1', messageId: 'm1'),
        ),
      ),
    );
    await tester.pump();
    expect(container.read(currentThreadIdProvider), 'm1');

    // 화면을 걷어 내 dispose 를 태운다 — 뒤로 가기와 같은 경로다.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(container.read(currentThreadIdProvider), isNull);
  });
}
