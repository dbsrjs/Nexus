import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/invite.dart';
import 'package:nexus_app/domain/models/space.dart';
import 'package:nexus_app/domain/models/space_member.dart';
import 'package:nexus_app/domain/models/user.dart';
import 'package:nexus_app/features/auth/auth_controller.dart';
import 'package:nexus_app/features/space/members_controller.dart';
import 'package:nexus_app/features/space_settings/invites_section.dart';
import 'package:nexus_app/features/space_settings/members_section.dart';
import 'package:nexus_app/features/space_settings/space_settings_controller.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/nx_host.dart';

/// 16단계 스페이스 설정 창.
void main() {
  group('섹션', () {
    test('★ member · 손님에게는 멤버 섹션만 보인다', () {
      expect(SpaceSettingsSection.visibleFor(SpaceRole.member), [SpaceSettingsSection.members]);
      expect(SpaceSettingsSection.visibleFor(SpaceRole.guest), [SpaceSettingsSection.members]);
    });
    test('admin · owner 에게는 셋', () {
      expect(SpaceSettingsSection.visibleFor(SpaceRole.admin), SpaceSettingsSection.values);
      expect(SpaceSettingsSection.visibleFor(SpaceRole.owner), SpaceSettingsSection.values);
    });
    test('주소', () {
      expect(spaceSettingsLocation('s1', SpaceSettingsSection.invites), '/s/s1/settings/invites');
      expect(spaceSettingsLocation('s1', null), '/s/s1/settings');
      expect(SpaceSettingsSection.parse('nope'), isNull);
    });
  });

  group('멤버 섹션', () {
    const members = [
      SpaceMemberProfile(userId: 'u1', name: '나', role: SpaceRole.admin),
      SpaceMemberProfile(userId: 'u2', name: 'Other Admin', role: SpaceRole.admin),
      SpaceMemberProfile(userId: 'u3', name: 'Member C', role: SpaceRole.member),
      SpaceMemberProfile(userId: 'u4', name: 'Owner', role: SpaceRole.owner),
    ];

    Future<void> pump(WidgetTester tester, SpaceRole me) => tester.pumpWidget(
          ProviderScope(
            overrides: [
              authControllerProvider.overrideWith(_SignedIn.new),
              spaceMembersOfProvider.overrideWith((ref, spaceId) async => members),
            ],
            child: nxTestApp(home: NxPage(body: MembersSection(spaceId: 's1', me: me))),
          ),
        );

    testWidgets('★ admin 은 member 줄에만 동작 메뉴가 있다 - 같은 admin · owner · 나는 없다', (tester) async {
      await pump(tester, SpaceRole.admin);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Member C의 동작'), findsOneWidget);
      expect(find.bySemanticsLabel('Other Admin의 동작'), findsNothing);
      expect(find.bySemanticsLabel('Owner의 동작'), findsNothing);
      expect(find.bySemanticsLabel('나의 동작'), findsNothing);
      expect(find.text('관리자'), findsNWidgets(2));
    });

    testWidgets('member 에게는 동작 메뉴가 하나도 없다', (tester) async {
      await pump(tester, SpaceRole.member);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('의 동작\$')), findsNothing);
      expect(find.text('멤버 4명'), findsOneWidget);
    });
  });

  test('초대 한 줄 설명', () {
    final invite = Invite(
      id: 'i1',
      code: 'abcdefghjk23',
      role: SpaceRole.member,
      useCount: 2,
      maxUses: 10,
      expiresAt: DateTime(2026, 10, 11, 12).toUtc(),
      createdByName: '가영',
    );
    expect(inviteSummary(invite), '멤버 · 10월 11일까지 · 8회 남음 · 가영');
    expect(
      inviteSummary(const Invite(id: 'i2', code: 'x', role: SpaceRole.guest, useCount: 0)),
      '손님 · 무기한 · 횟수 무제한',
    );
  });
}

class _SignedIn extends AuthController {
  @override
  AuthState build() => const AuthSignedIn(User(id: 'u1', email: 'a@x.io', name: '나'));
}
