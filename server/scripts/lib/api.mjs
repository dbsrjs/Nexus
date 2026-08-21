// 계약 검증 스크립트의 공용 HTTP 헬퍼.
//
// **주소를 아는 곳은 여기 하나다.** 이전에는 11벌이 각자 BASE 를 선언해,
// 주소가 바뀌면 열한 곳을 고쳐야 했다. 앱의 core/env.dart 와 같은 규칙이다.

export const BASE = 'http://127.0.0.1:3000/api';

// 한 프로세스 안에서 값이 하나여야 한다는 뜻을 모듈로 표현한다.
// base36 은 짧아서 스페이스 이름·이메일에 끼워 넣기 좋다. 이전에는 이 형태와
// Date.now() 가 섞여 있었다.
export const stamp = Date.now().toString(36);

export async function api(method, path, { token, body } = {}) {
  const res = await fetch(BASE + path, {
    method,
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  let json = null;
  try {
    json = await res.json();
  } catch {
    /* 본문 없음 */
  }
  return { status: res.status, json };
}

// 검증용 계정을 만든다. 비밀번호는 어디서도 재사용되지 않으므로(로그인하는
// 스크립트는 check-realtime 하나뿐이고 그것은 시드 계정을 쓴다) 상수로 둔다.
const PASSWORD = 'check-harness-1234';

/**
 * @param prefix 이메일 접두사. 스크립트마다 다르게 주어 계정이 섞이지 않게 한다
 * @param tag    같은 스크립트 안에서 계정을 가르는 꼬리표
 * @param name   표시 이름. **check-mentions 는 이 값을 단언에 쓰므로**
 *               반드시 자기 이름을 명시적으로 넘긴다
 */
export async function signup(prefix, tag, name = `${prefix}검증${tag}`) {
  const res = await api('POST', '/auth/signup', {
    body: {
      email: `${prefix}-${tag}-${stamp}@example.com`,
      password: PASSWORD,
      name,
      client: 'native',
    },
  });
  if (res.status !== 201) {
    console.error('가입 실패:', res.status, JSON.stringify(res.json));
    process.exit(1);
  }
  return { token: res.json.accessToken, userId: res.json.user.id };
}
