import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/connection.dart';
import 'package:nexus_app/domain/models/repo.dart';
import 'package:nexus_app/features/repo/connection_controller.dart';
import 'package:nexus_app/features/repo/repo_controller.dart';
import 'package:nexus_app/features/repo/repos_screen.dart';

/// Riverpod 3 은 `Override` 를 export 하지 않아 목록에 타입을 붙일 수 없다.
/// 그래서 적재 함수를 받는다(10-2a 의 repos_screen_test 와 같은 방식).
Widget harness({
  required Future<List<GithubConnection>> Function() connections,
  required Future<List<SpaceRepo>> Function() repos,
}) {
  return ProviderScope(
    overrides: [
      connectionsProvider.overrideWith((ref) => connections()),
      spaceReposProvider('space-1').overrideWith((ref) => repos()),
    ],
    child: const MaterialApp(home: ReposScreen(spaceId: 'space-1')),
  );
}

final _connected = GithubConnection(
  provider: 'github',
  login: 'octocat',
  avatarUrl: null,
  connectedAt: DateTime.utc(2026, 8, 20),
);

void main() {
  testWidgets('붙은 저장소가 경로로 보인다', (tester) async {
    await tester.pumpWidget(harness(
      connections: () async => [_connected],
      repos: () async => const [
        SpaceRepo(
          id: 'r1',
          name: 'hello-world',
          fullPath: 'octocat/hello-world',
          linkedChannelId: 'c1',
          webhookExternalId: '700',
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('octocat/hello-world'), findsOneWidget);
    expect(find.text('다시 걸기'), findsNothing);
  });

  testWidgets('훅이 안 걸린 저장소에는 다시 걸기가 뜬다', (tester) async {
    await tester.pumpWidget(harness(
      connections: () async => [_connected],
      repos: () async => const [
        SpaceRepo(
          id: 'r1',
          name: 'hello-world',
          fullPath: 'octocat/hello-world',
          linkedChannelId: null,
          webhookExternalId: null,
        ),
      ],
    ));
    await tester.pumpAndSettle();

    // 실패를 조용히 두면 사용자는 커밋이 왜 안 오는지 알 수 없다.
    expect(find.text('웹훅 등록 실패'), findsOneWidget);
    expect(find.text('다시 걸기'), findsOneWidget);
  });

  testWidgets('연결 전에는 저장소 목록을 부르지 않는다', (tester) async {
    var called = false;
    await tester.pumpWidget(harness(
      connections: () async => const <GithubConnection>[],
      repos: () async {
        called = true;
        return const <SpaceRepo>[];
      },
    ));
    await tester.pumpAndSettle();

    // 연결이 없으면 서버가 400 이다. 부르지 않는 것이 맞다.
    expect(called, isFalse);
    expect(find.text('GitHub 연결'), findsOneWidget);
  });
}
