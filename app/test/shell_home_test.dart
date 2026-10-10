import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/channel.dart';
import 'package:nexus_app/features/channel/channel_controller.dart';
import 'package:nexus_app/features/shell/app_shell.dart';

Channel _channel(String id, {String kind = 'text'}) =>
    Channel(id: id, key: id, name: id, kind: kind);

void main() {
  group('firstHomeChannel — 넓은 셸이 곧장 열 첫 채널', () {
    test('사이드바 순서의 첫 글 채널', () {
      final groups = [
        ChannelGroup(title: 'A', channels: [_channel('a1'), _channel('a2')]),
        ChannelGroup(title: 'B', channels: [_channel('b1')]),
      ];
      expect(firstHomeChannel(groups)?.id, 'a1');
    });

    test('★ 글 채널이 아닌 것(음성 등)은 건너뛴다 — 여는 순간 동작이 시작될 수 있다', () {
      final groups = [
        ChannelGroup(
          title: 'A',
          channels: [_channel('v1', kind: 'voice')],
        ),
        ChannelGroup(
          title: 'B',
          channels: [
            _channel('v2', kind: 'voice'),
            _channel('t1'),
          ],
        ),
      ];
      expect(firstHomeChannel(groups)?.id, 't1');
    });

    test('글 채널이 없으면 null — 빈 화면 안내가 맡는다', () {
      final groups = [
        ChannelGroup(
          title: 'A',
          channels: [_channel('v1', kind: 'voice')],
        ),
      ];
      expect(firstHomeChannel(groups), isNull);
      expect(firstHomeChannel(const []), isNull);
    });
  });
}
