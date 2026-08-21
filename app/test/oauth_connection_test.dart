import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/socket/socket_event.dart';

void main() {
  group('OauthConnected', () {
    test('provider 와 login 을 담는다', () {
      const event = OauthConnected(provider: 'github', login: 'octocat');

      expect(event.provider, 'github');
      expect(event.login, 'octocat');
    });

    test('SocketEvent 의 한 갈래다', () {
      // sealed 라 화면이 switch 로 받을 때 빠뜨리면 컴파일이 막힌다.
      const SocketEvent event = OauthConnected(
        provider: 'github',
        login: 'octocat',
      );

      expect(event, isA<SocketEvent>());
    });
  });
}
