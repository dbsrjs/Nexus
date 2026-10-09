import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/data/api/invites_api.dart';
import 'package:nexus_app/data/repositories/workspace_repository.dart';
import 'package:nexus_app/features/space/invite_screen.dart';
import 'package:nexus_app/features/space/members_controller.dart';
import 'package:nexus_app/features/space/space_controller.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/nx_host.dart';

/// 초대 링크로 들어온 화면(«마지막» 딥링크).
void main() {
  late _FakeInvitesApi invites;
  late _FakeWorkspace workspace;

  setUp(() {
    invites = _FakeInvitesApi();
    workspace = _FakeWorkspace();
  });

  Future<GoRouter> open(WidgetTester tester, String location) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/invite/:code',
          builder: (_, s) => InviteScreen(rawCode: s.pathParameters['code']!),
        ),
        GoRoute(
          path: '/s/:id',
          builder: (_, s) => Text('space ${s.pathParameters['id']}'),
        ),
        GoRoute(path: '/spaces', builder: (_, _) => const Text('picker')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          invitesApiProvider.overrideWithValue(invites),
          workspaceRepositoryProvider.overrideWithValue(workspace),
        ],
        child: nxTestApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('★ 열자마자 참여시키지 않는다 - 한 번 더 누르게 한다', (tester) async {
    await open(tester, '/invite/abcdefghjk23');
    expect(invites.accepted, isEmpty);
    expect(find.textContaining('abcdefghjk23'), findsOneWidget);
  });

  testWidgets('★ 참여하면 스페이스 목록을 다시 받고 그 스페이스로 간다', (tester) async {
    await open(tester, '/invite/ABCDEFGHJK23');
    await tester.tap(find.widgetWithText(NxButton, '참여'));
    await tester.pumpAndSettle();
    // 주소의 대소문자는 붙여넣기와 같은 규칙으로 접는다.
    expect(invites.accepted, ['abcdefghjk23']);
    expect(workspace.refreshed, 1);
    expect(find.text('space s1'), findsOneWidget);
  });

  testWidgets('★ 실패하면 이유를 보이고 머문다', (tester) async {
    invites.acceptError = ApiFailure.badRequest;
    await open(tester, '/invite/abcdefghjk23');
    await tester.tap(find.widgetWithText(NxButton, '참여'));
    await tester.pumpAndSettle();
    expect(find.text('만료됐거나 사용 한도가 찬 초대 코드입니다'), findsOneWidget);
    expect(find.widgetWithText(NxButton, '참여'), findsOneWidget);
  });

  testWidgets('코드로 읽히지 않는 주소면 참여 버튼이 없다', (tester) async {
    await open(tester, '/invite/nope');
    expect(find.widgetWithText(NxButton, '참여'), findsNothing);
    await tester.tap(find.widgetWithText(NxButton, '스페이스 목록으로'));
    await tester.pumpAndSettle();
    expect(find.text('picker'), findsOneWidget);
  });
}

class _FakeInvitesApi implements InvitesApi {
  ApiFailure? acceptError;
  final accepted = <String>[];

  @override
  Future<String> accept(String code) async {
    accepted.add(code);
    if (acceptError != null) throw ApiException(acceptError!);
    return 's1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeWorkspace implements WorkspaceRepository {
  int refreshed = 0;

  @override
  Future<bool> refreshSpaces() async {
    refreshed++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
