import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/channel_access.dart';
import 'package:nexus_app/domain/models/space.dart';
import 'package:nexus_app/features/channel_settings/channel_settings_controller.dart';
import 'package:nexus_app/features/channel_settings/permissions_section.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/nx_host.dart';

/// 16-2 채널 설정 창.
void main() {
  group('섹션', () {
    List<ChannelSettingsSection> visible(bool private, SpaceRole role) =>
        ChannelSettingsSection.visibleFor(isPrivate: private, role: role);

    test('★ 비공개 채널은 명단이 있고 권한이 없다(D19 · D22)', () {
      expect(visible(true, SpaceRole.admin), [ChannelSettingsSection.overview, ChannelSettingsSection.members]);
      expect(visible(true, SpaceRole.guest), [ChannelSettingsSection.overview, ChannelSettingsSection.members]);
    });

    test('★ 공개 채널의 권한은 admin+ 만 본다', () {
      expect(visible(false, SpaceRole.admin), [ChannelSettingsSection.overview, ChannelSettingsSection.permissions]);
      expect(visible(false, SpaceRole.member), [ChannelSettingsSection.overview]);
    });

    test('주소', () {
      expect(channelSettingsLocation('s', 'c', null), '/s/s/c/c/settings');
      expect(channelSettingsLocation('s', 'c', ChannelSettingsSection.members), '/s/s/c/c/settings/members');
    });
  });

  test('★ 명단 줄의 동작 — 본인은 나가기, 남은 admin+ 만 빼기(D18)', () {
    expect(memberRowAction(self: true, me: SpaceRole.guest), MemberRowAction.leave);
    expect(memberRowAction(self: false, me: SpaceRole.admin), MemberRowAction.remove);
    expect(memberRowAction(self: false, me: SpaceRole.member), MemberRowAction.none);
  });

  testWidgets('★ 가린 역할은 「보내기」 스위치가 꺼진 채로 눌리지 않는다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: nxTestApp(
          home: NxPage(
            body: PermissionRow(
              permission: const RolePermission(
                role: SpaceRole.member,
                canView: false,
                canSend: false,
                explicit: true,
              ),
              enabled: true,
              onView: (_) {},
              onSend: (_) {},
              onReset: () {},
            ),
          ),
        ),
      ),
    );
    final send = tester.widget<NxSwitch>(
      find.byWidgetPredicate((w) => w is NxSwitch && w.label == '멤버 보내기'),
    );
    final view = tester.widget<NxSwitch>(
      find.byWidgetPredicate((w) => w is NxSwitch && w.label == '멤버 보기'),
    );
    expect(send.onChanged, isNull);
    expect(view.onChanged, isNotNull);
    expect(find.text('기본값으로'), findsOneWidget);
    expect(find.text('예외 적용 중'), findsOneWidget);
  });
}
