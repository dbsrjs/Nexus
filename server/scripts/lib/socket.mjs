// 계약 검증의 공용 소켓 헬퍼.
//
// **socket.io-client 를 import 하는 곳은 여기 하나다.** 소켓을 쓰지 않는
// 스크립트(attachments · mentions · oauth · repos · browse)가 그것을 로드하지
// 않도록 파일을 갈랐다.
import { io } from 'socket.io-client';

export const WS = 'http://127.0.0.1:3000';

/**
 * 연결되면 소켓을, 거부되면 오류를 돌려준다(던지지 않는다) — 거부되는 것
 * 자체가 검증 대상이기 때문이다.
 *
 * token 이 undefined 면 auth 를 통째로 비운다. `{ token: undefined }` 를
 * 보내는 것과 다르고, "토큰 없이 연결하면 거부"를 시험하려면 이쪽이어야 한다.
 */
export function connect(token) {
  return new Promise((resolve) => {
    const socket = io(WS, {
      auth: token === undefined ? {} : { token },
      transports: ['websocket'],
      reconnection: false,
      timeout: 5000,
    });
    socket.once('connect', () => resolve(socket));
    socket.once('connect_error', (err) => resolve(err));
  });
}

/** 이벤트를 기다린다. 시간 안에 안 오면 null — 그것도 검증 대상이다. */
export function waitFor(socket, event, ms = 3000) {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      socket.off(event, handler);
      resolve(null);
    }, ms);
    const handler = (payload) => {
      clearTimeout(timer);
      resolve(payload);
    };
    socket.once(event, handler);
  });
}
