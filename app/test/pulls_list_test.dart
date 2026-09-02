import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/api_failure.dart';
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

  /// 어떤 필터로 불렀는지. 필터 전환이 실제로 서버까지 가는지 본다.
  final states = <String>[];

  /// 응답을 붙잡아 두고 싶을 때. 로딩 중 화면을 보려면 필요하다.
  Completer<void>? gate;

  /// 「닫힘」 필터의 첫 장.
  ({List<PullSummary> pulls, int? nextPage})? closedFirstPage;

  @override
  Future<({List<PullSummary> pulls, int? nextPage})> list(
    String spaceId,
    String repoId, {
    String state = 'open',
    int page = 1,
  }) async {
    calls.add(page);
    states.add(state);
    if (gate != null) await gate!.future;
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

/// 첫 장을 provider override 로 준다. `key.state` 를 보므로 필터 전환도 탄다.
Widget harness(FakePullsApi api, {Object? firstPageError}) {
  return ProviderScope(
    overrides: [
      pullsApiProvider.overrideWithValue(api),
      pullsProvider.overrideWith((ref, key) async {
        if (firstPageError != null) throw firstPageError;
        api.states.add(key.state);
        return key.state == 'closed'
            ? (api.closedFirstPage ?? (pulls: const <PullSummary>[], nextPage: null))
            : (api.pages[1] ?? (pulls: const <PullSummary>[], nextPage: null));
      }),
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

  testWidgets('필터를 바꾸면 그 상태로 다시 부르고 이어 받은 것을 버린다', (tester) async {
    final api = FakePullsApi({
      1: (pulls: [for (var i = 1; i <= 3; i++) pull(i)], nextPage: 2),
      2: (pulls: [pull(31)], nextPage: null),
    })..closedFirstPage = (pulls: [pull(99)], nextPage: null);

    await tester.pumpWidget(harness(api));
    await tester.pumpAndSettle();

    // 먼저 2장을 이어 받아 둔다.
    await tester.tap(find.text('더 불러오기'));
    await tester.pumpAndSettle();
    expect(find.text('#31 · 제목 31'), findsOneWidget);

    await tester.tap(find.text('닫힘'));
    await tester.pumpAndSettle();

    expect(api.states.last, 'closed', reason: '바뀐 필터로 서버를 부른다');
    expect(find.text('#99 · 제목 99'), findsOneWidget);
    // **이어 받아 둔 것이 남으면 안 된다** — 「열림」 에서 받은 PR 이
    // 「닫힘」 목록에 섞인다.
    expect(find.text('#31 · 제목 31'), findsNothing);
    expect(find.text('#1 · 제목 1'), findsNothing);
  });

  testWidgets('이어 받는 동안 버튼 자리가 스피너로 바뀐다', (tester) async {
    // 예전에는 버튼이 아예 사라져 목록이 튀고, 누른 것이 먹었는지 알 수 없었다.
    final api = FakePullsApi({
      1: (pulls: [for (var i = 1; i <= 3; i++) pull(i)], nextPage: 2),
      2: (pulls: [pull(31)], nextPage: null),
    });

    await tester.pumpWidget(harness(api));
    await tester.pumpAndSettle();

    api.gate = Completer<void>();
    await tester.tap(find.text('더 불러오기'));
    await tester.pump();

    expect(find.text('더 불러오기'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    api.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('미연결(400)일 때만 저장소 화면으로 가는 길을 보여 준다', (tester) async {
    // 400 이 `server` 로 접혀 있던 동안에는 진짜 서버 오류에도
    // «GitHub 을 연결하세요» 가 떴다.
    await tester.pumpWidget(harness(
      FakePullsApi(const {}),
      firstPageError: const ApiException(ApiFailure.badRequest),
    ));
    await tester.pumpAndSettle();

    expect(find.text('GitHub 을 연결하세요'), findsOneWidget);
    expect(find.text('저장소 화면으로'), findsOneWidget);
  });

  testWidgets('그 밖의 실패는 다시 확인만 준다', (tester) async {
    await tester.pumpWidget(harness(
      FakePullsApi(const {}),
      firstPageError: const ApiException(ApiFailure.server),
    ));
    await tester.pumpAndSettle();

    expect(find.text('GitHub 을 연결하세요'), findsNothing);
    expect(find.text('다시 확인'), findsOneWidget);
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
