import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/connection.dart';
import 'package:nexus_app/features/repo/connection_controller.dart';
import 'package:nexus_app/features/repo/repos_screen.dart';

/// 9-3 에서 서버만 만들고 화면을 빠뜨린 채 완료로 보고한 일이 있었다.
/// 이 테스트는 그 구멍을 막는 자리다.
///
/// **override 목록이 아니라 적재 함수를 받는다.** Riverpod 3 은 `Override` 를
/// 더 이상 export 하지 않아 목록에 타입을 붙일 수 없다.
Widget harness(Future<List<GithubConnection>> Function() load) {
  return ProviderScope(
    overrides: [connectionsProvider.overrideWith((ref) => load())],
    child: const MaterialApp(home: ReposScreen(spaceId: 'space-1')),
  );
}

void main() {
  testWidgets('연결 전에는 연결 버튼을 보여 준다', (tester) async {
    await tester.pumpWidget(harness(() async => const <GithubConnection>[]));
    await tester.pumpAndSettle();

    expect(find.text('GitHub 연결'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
  });

  testWidgets('연결되면 계정과 해제 버튼을 보여 준다', (tester) async {
    await tester.pumpWidget(harness(() async => [
          GithubConnection(
            provider: 'github',
            login: 'octocat',
            avatarUrl: null,
            connectedAt: DateTime.utc(2026, 8, 20),
          ),
        ]));
    await tester.pumpAndSettle();

    expect(find.text('@octocat'), findsOneWidget);
    expect(find.text('연결 해제'), findsOneWidget);
    expect(find.text('GitHub 연결'), findsNothing);
  });

  testWidgets('불러오지 못하면 다시 시도할 길을 남긴다', (tester) async {
    await tester.pumpWidget(harness(() async => throw Exception('offline')));
    await tester.pumpAndSettle();

    // 조용히 빈 화면을 그리면 "연결 안 됨"과 구분되지 않는다.
    expect(find.text('다시 확인'), findsOneWidget);
  });
}
