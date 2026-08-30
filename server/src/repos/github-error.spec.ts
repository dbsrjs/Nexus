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
});
