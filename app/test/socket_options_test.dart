import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/socket/socket_client.dart';

void main() {
  test('★ 연결마다 새 Manager 를 만든다 - 캐시된 소켓이 옛 토큰을 다시 보내지 않게', () {
    // API 주소에 경로가 없어 socket_io_client 의 캐시가 이름공간을 못 알아보고 옛 Socket
    // (옛 auth)을 돌려줬다 — 토큰을 갱신하고 다시 붙어도 옛 토큰으로 거부당해 영영 끊겨
    // 있었다(2026-10-07 웹 확인에서 발견).
    final opts = socketOptions('new-token');
    expect(opts['forceNew'], isTrue);
    expect(opts['auth'], {'token': 'new-token'});
  });

  test('전송은 websocket 하나 · 자동 연결은 끄고 재연결은 켠다', () {
    final opts = socketOptions('t');
    expect(opts['transports'], ['websocket']);
    expect(opts['autoConnect'], isFalse);
    // enableReconnection() 은 키를 지워 기본값(켜짐)으로 둔다 — 꺼져 있지 않은지만 본다.
    expect(opts['reconnection'], isNot(false));
  });
}
