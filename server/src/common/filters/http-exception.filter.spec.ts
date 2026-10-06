import { ArgumentsHost, Logger, NotFoundException } from '@nestjs/common';
import { HttpExceptionFilter } from './http-exception.filter';

function hostWith() {
  const json = jest.fn();
  const response = {
    status: jest.fn(() => ({ json })),
    setHeader: jest.fn(),
  };
  const host = {
    switchToHttp: () => ({
      getResponse: () => response,
      getRequest: () => ({ url: '/api/x' }),
    }),
  } as unknown as ArgumentsHost;
  return { host, response, json };
}

describe('HttpExceptionFilter', () => {
  beforeAll(() => {
    // 의도한 오류 로그가 테스트 출력을 덮지 않게 한다.
    jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
  });

  it('★ HttpException 이 아닌 Error 의 원문은 응답에 싣지 않는다 — DB 호스트 · 키 길이가 샌다', () => {
    const { host, response, json } = hostWith();
    new HttpExceptionFilter().catch(
      new Error("Can't reach database server at `db.internal:5432`"),
      host,
    );

    expect(response.status).toHaveBeenCalledWith(500);
    const body = json.mock.calls[0][0];
    expect(body.message).toBe('Internal server error');
    expect(JSON.stringify(body)).not.toContain('db.internal');
  });

  it('HttpException 의 문구는 그대로 준다 — 의도해서 던진 것이다', () => {
    const { host, json } = hostWith();
    new HttpExceptionFilter().catch(
      new NotFoundException('채널을 찾을 수 없습니다'),
      host,
    );

    expect(json.mock.calls[0][0]).toMatchObject({
      statusCode: 404,
      message: '채널을 찾을 수 없습니다',
    });
  });
});
