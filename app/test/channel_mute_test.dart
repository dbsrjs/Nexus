import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/channel.dart';
import 'package:nexus_app/features/channel/channel_controller.dart';
import 'package:nexus_app/features/channel/channel_list.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/nx_host.dart';

/// 음소거한 채널의 목록 표시(14단계 설계 D17). 디스코드와 같다 —
/// **안 읽음 표시는 끄고, 나를 부른 멘션은 남긴다.**
void main() {
  Future<void> pump(WidgetTester tester, List<Channel> channels) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          channelsProvider.overrideWith((ref) => Stream.value(channels)),
          categoriesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: nxTestApp(home: const NxPage(body: ChannelList()),
        ),
      ),
    );
    await tester.pump();
  }

  Channel channel(String name, {bool muted = false}) => Channel(
        id: name,
        key: name,
        name: name,
        unreadCount: 7,
        mentionCount: 3,
        muted: muted,
      );

  testWidgets('음소거하지 않은 채널은 안 읽은 수와 멘션을 모두 보인다', (tester) async {
    await pump(tester, [channel('loud')]);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('@3'), findsOneWidget);
  });

  testWidgets('★ 음소거한 채널은 안 읽은 수를 끄고 멘션은 남긴다', (tester) async {
    await pump(tester, [channel('quiet', muted: true)]);
    expect(find.text('7'), findsNothing);
    expect(find.text('@3'), findsOneWidget);
  });

  testWidgets('★ 음소거한 채널은 안 읽은 것이 있어도 굵지 않고 흐리다', (tester) async {
    await pump(tester, [channel('loud'), channel('quiet', muted: true)]);
    final loud = tester.widget<Text>(find.text('loud')).style!;
    final quiet = tester.widget<Text>(find.text('quiet')).style!;
    expect(loud.fontWeight, FontWeight.w600);
    expect(quiet.fontWeight, FontWeight.w400);
    expect(quiet.color, isNot(loud.color));
  });
}
