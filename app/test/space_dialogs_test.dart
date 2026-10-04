import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/data/api/invites_api.dart';
import 'package:nexus_app/domain/models/invite.dart';
import 'package:nexus_app/domain/models/space.dart';
import 'package:nexus_app/features/space/members_controller.dart';
import 'package:nexus_app/features/space/space_dialogs.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/nx_host.dart';

/// 16단계 — 초대 코드로 참여(설계 D2 · D3).
void main() {
  late _FakeInvitesApi invites;

  setUp(() => invites = _FakeInvitesApi());

  Future<void> openJoin(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [invitesApiProvider.overrideWithValue(invites)],
        child: nxTestApp(
          home: NxPage(
            body: Consumer(
              builder: (context, ref, _) => NxButton(
                label: '열기',
                onPressed: () => showJoinSpaceDialog(context, ref),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(NxButton, '열기'));
    await tester.pumpAndSettle();
  }

  NxButton join(WidgetTester tester) =>
      tester.widget<NxButton>(find.widgetWithText(NxButton, '참여'));

  testWidgets('★ 코드가 없는 글이면 참여 버튼이 꺼져 있다', (tester) async {
    await openJoin(tester);
    expect(join(tester).onPressed, isNull);
    await tester.enterText(find.byType(NxField), '코드 없음');
    await tester.pump();
    expect(join(tester).onPressed, isNull);
  });

  testWidgets('★ 문장째 붙여넣으면 코드만 보낸다', (tester) async {
    invites.acceptError = ApiFailure.badRequest;
    await openJoin(tester);
    await tester.enterText(find.byType(NxField), '초대 코드: ABCDEFGHJK23 입니다');
    await tester.pump();
    await tester.tap(find.widgetWithText(NxButton, '참여'));
    await tester.pumpAndSettle();
    expect(invites.accepted, ['abcdefghjk23']);
    expect(find.text('만료됐거나 사용 한도가 찬 초대 코드입니다'), findsOneWidget);
  });

  testWidgets('★ 수락이 404 면 「없는 초대 코드입니다」 - 서버 문구를 쓰지 않는다', (tester) async {
    invites.acceptError = ApiFailure.notFound;
    await openJoin(tester);
    await tester.enterText(find.byType(NxField), 'abcdefghjk23');
    await tester.pump();
    await tester.tap(find.widgetWithText(NxButton, '참여'));
    await tester.pumpAndSettle();
    expect(find.text('없는 초대 코드입니다'), findsOneWidget);
  });

  test('그 밖의 실패는 공통 문구', () {
    expect(joinMessageFor(ApiFailure.network), messageFor(ApiFailure.network));
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
  Future<Invite> create(String spaceId,
          {required SpaceRole role, int? expiresInHours, int? maxUses}) =>
      throw UnimplementedError();

  @override
  Future<List<Invite>> list(String spaceId) => throw UnimplementedError();

  @override
  Future<void> revoke(String spaceId, String inviteId) => throw UnimplementedError();
}
