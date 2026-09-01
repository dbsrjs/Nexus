import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/pulls_api.dart';
import 'package:nexus_app/domain/models/pull.dart';
import 'package:nexus_app/features/repo/browse_controller.dart';
import 'package:nexus_app/features/repo/pulls_screen.dart';

/// **`implements` 로 만든다** — `PullsApi` 는 `ApiClient` 를 받는데 테스트에는
/// 줄 것이 없다. 생성자를 부르지 않으므로 공개 메서드 셋만 채우면 된다.
class FakePullsApi implements PullsApi {
  FakePullsApi(this.pages);

  /// page 번호 → 그 장의 응답.
  final Map<int, ({List<PullSummary> pulls, int? nextPage})> pages;

  /// 어느 장을 몇 번 불렀는지. 같은 장을 다시 부르는 결함을 잡는 데 쓴다.
  final calls = <int>[];

  @override
  Future<({List<PullSummary> pulls, int? nextPage})> list(
    String spaceId,
    String repoId, {
    String state = 'open',
    int page = 1,
  }) async {
    calls.add(page);
    return pages[page] ?? (pulls: const <PullSummary>[], nextPage: null);
  }

  @override
  Future<PullDetail> detail(String spaceId, String repoId, int number) async =>
      throw UnimplementedError();

  @override
  Future<({List<PullChangedFile> files, bool truncated})> files(
    String spaceId,
    String repoId,
    int number,
  ) async =>
      throw UnimplementedError();
}

PullSummary pull(int n) => PullSummary(
      number: n,
      title: '제목 $n',
      state: PullState.open,
      sourceBranch: 'feat/$n',
      targetBranch: 'main',
    );

Widget harness(FakePullsApi api) {
  final first = api.pages[1] ?? (pulls: const <PullSummary>[], nextPage: null);
  return ProviderScope(
    overrides: [
      pullsApiProvider.overrideWithValue(api),
      pullsProvider.overrideWith((ref, key) async => first),
    ],
    child: const MaterialApp(
      home: PullsScreen(spaceId: 'space-1', repoId: 'repo-1'),
    ),
  );
}

void main() {
  testWidgets('이어 받은 장이 비면 «더 불러오기» 가 사라진다', (tester) async {
    // **PR 이 정확히 30건일 때 실제로 걸리던 결함이다.** 첫 장이 30건을 채워
    // nextPage 가 2 가 되고, 2장은 빈 배열로 온다. 다음 장 번호를 «이어 받은
    // 것이 비었는가» 로 고르면 첫 장의 nextPage(=2) 로 되돌아가, 버튼이
    // 사라지지 않은 채 같은 장을 무한히 다시 부른다.
    final api = FakePullsApi({
      // 개수는 3이면 된다 — `ListView` 가 지연 렌더라 30개를 두면 버튼이
      // 화면 밖이라 찾히지 않는다. 결함을 만드는 조건은 개수가 아니라
      // «첫 장의 nextPage 가 있고, 이어 받은 장이 비어 있다» 이다.
      1: (pulls: [for (var i = 1; i <= 3; i++) pull(i)], nextPage: 2),
      2: (pulls: const <PullSummary>[], nextPage: null),
    });

    await tester.pumpWidget(harness(api));
    await tester.pumpAndSettle();

    expect(find.text('더 불러오기'), findsOneWidget);

    await tester.ensureVisible(find.text('더 불러오기'));
    await tester.tap(find.text('더 불러오기'));
    await tester.pumpAndSettle();

    expect(api.calls, [2], reason: '2장을 한 번만 불러야 한다');
    expect(find.text('더 불러오기'), findsNothing, reason: '더 받을 것이 없다');
  });

  testWidgets('이어 받을 것이 남았으면 그다음 장을 부른다', (tester) async {
    final api = FakePullsApi({
      1: (pulls: [for (var i = 1; i <= 3; i++) pull(i)], nextPage: 2),
      2: (pulls: [pull(31)], nextPage: 3),
      3: (pulls: [pull(32)], nextPage: null),
    });

    await tester.pumpWidget(harness(api));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('더 불러오기'));
    await tester.tap(find.text('더 불러오기'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('더 불러오기'));
    await tester.tap(find.text('더 불러오기'));
    await tester.pumpAndSettle();

    expect(api.calls, [2, 3], reason: '장 번호가 이어져야 한다');
    expect(find.text('더 불러오기'), findsNothing);
  });

  testWidgets('빈 목록 문구가 필터를 따라간다', (tester) async {
    // 「닫힘」 을 골랐는데 «열린 PR 이 없습니다» 라고 하면 필터가 안 먹은
    // 것으로 읽힌다.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PullList(pulls: const [], state: 'closed', onTap: (_) {}),
        ),
      ),
    );

    expect(find.text('닫힌 PR 이 없습니다'), findsOneWidget);
    expect(find.text('열린 PR 이 없습니다'), findsNothing);
  });
}
