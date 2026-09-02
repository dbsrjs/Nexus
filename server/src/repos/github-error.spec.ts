import { HttpStatus } from '@nestjs/common';
import { toGithubHttpError } from './github-error';

describe('toGithubHttpError', () => {
  it('429 는 retryAfter 를 본문 객체에 담는다 — 전역 필터가 헤더로 옮긴다', () => {
    const err = toGithubHttpError(429, 60);
    expect(err.getStatus()).toBe(HttpStatus.TOO_MANY_REQUESTS);
    expect(err.getResponse()).toMatchObject({ retryAfter: 60 });
  });

  it('Retry-After 가 없으면 null 이다 — 없는 것과 0 초는 다르다', () => {
    expect(toGithubHttpError(429).getResponse()).toMatchObject({ retryAfter: null });
  });

  it('404 는 그대로 전달한다', () => {
    expect(toGithubHttpError(404).getStatus()).toBe(HttpStatus.NOT_FOUND);
  });

  it('401 은 다시 연결하라고 말한다', () => {
    expect(toGithubHttpError(401).getStatus()).toBe(HttpStatus.UNAUTHORIZED);
  });

  it('그 밖은 502 다 — 우리 잘못이 아니라 GitHub 에서 못 받은 것이다', () => {
    expect(toGithubHttpError(500).getStatus()).toBe(HttpStatus.BAD_GATEWAY);
  });

  // **본문을 객체로 넘겨야 `error` 라벨이 채워진다.** 문자열로 넘기면 전역
  // 필터의 그 갈래가 라벨을 채우지 않아 기본값 InternalServerError 가 남는다 —
  // 401 응답이 `{"statusCode":401, …, "error":"InternalServerError"}` 로 나갔다.
  it.each([
    [404, 'NotFound'],
    [401, 'Unauthorized'],
    [500, 'BadGateway'],
    [429, 'TooManyRequests'],
  ])('%s 는 error 라벨이 %s 다', (status, label) => {
    expect(toGithubHttpError(status).getResponse()).toMatchObject({ error: label });
  });
});
