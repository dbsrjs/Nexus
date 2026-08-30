import { HttpException, HttpStatus } from '@nestjs/common';

/**
 * GitHub 의 실패를 우리 응답으로 옮긴다.
 *
 * **`retryAfter` 를 본문 객체에 담는다.** 전역 예외 필터가 그것을 읽어
 * `Retry-After` 헤더로 내보낸다 — 필터는 본문을 일정한 봉투로 다시 빚어
 * 커스텀 필드를 버리기 때문이다(10-3a 에서 잡은 결함).
 *
 * **404 는 그대로 전달한다** — 없는 브랜치 · 없는 경로 · 없는 PR 번호가 여기로
 * 온다. 저장소 자체가 없는 것과 구분되지 않지만, 앱이 할 일은 어느 쪽이든 같다.
 */
export function toGithubHttpError(status: number, retryAfter?: number): HttpException {
  if (status === 429) {
    return new HttpException(
      {
        statusCode: HttpStatus.TOO_MANY_REQUESTS,
        message: 'GitHub 요청 한도를 넘었습니다. 잠시 뒤 다시 시도해 주세요.',
        retryAfter: retryAfter ?? null,
      },
      HttpStatus.TOO_MANY_REQUESTS,
    );
  }
  if (status === 404) return new HttpException('찾을 수 없습니다', HttpStatus.NOT_FOUND);
  if (status === 401) {
    return new HttpException(
      'GitHub 연결이 만료되었습니다. 다시 연결해 주세요.',
      HttpStatus.UNAUTHORIZED,
    );
  }
  return new HttpException('GitHub 에서 받지 못했습니다.', HttpStatus.BAD_GATEWAY);
}
