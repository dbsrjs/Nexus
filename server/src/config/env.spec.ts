import { ConfigService } from '@nestjs/config';
import { resolveTrustProxy } from './env';

function fakeConfig(values: Record<string, string>): ConfigService {
  return { get: (key: string) => values[key] } as unknown as ConfigService;
}

describe('resolveTrustProxy', () => {
  it('비우면 끈다 — 직접 받는 개발 서버', () => {
    expect(resolveTrustProxy(fakeConfig({}))).toBeNull();
    expect(resolveTrustProxy(fakeConfig({ TRUST_PROXY: '  ' }))).toBeNull();
  });

  it('숫자는 홉 수다 — 문자열 "1" 이면 Express 가 주소로 읽는다', () => {
    expect(resolveTrustProxy(fakeConfig({ TRUST_PROXY: '1' }))).toBe(1);
  });

  it('주소 목록은 그대로 넘긴다', () => {
    expect(resolveTrustProxy(fakeConfig({ TRUST_PROXY: 'loopback, uniquelocal' }))).toBe(
      'loopback, uniquelocal',
    );
  });

  it('true 는 거부한다 — 지어낸 X-Forwarded-For 로 시도 제한을 피하게 된다', () => {
    expect(() => resolveTrustProxy(fakeConfig({ TRUST_PROXY: 'true' }))).toThrow();
    expect(() => resolveTrustProxy(fakeConfig({ TRUST_PROXY: '*' }))).toThrow();
  });
});
