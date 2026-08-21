import { ConfigService } from '@nestjs/config';
import { resolvePublicBaseUrl } from './public-url.config';

function fakeConfig(values: Record<string, string>): ConfigService {
  return { get: (key: string) => values[key] } as unknown as ConfigService;
}

describe('resolvePublicBaseUrl', () => {
  it('값이 있으면 그대로 준다', () => {
    expect(
      resolvePublicBaseUrl(fakeConfig({ PUBLIC_BASE_URL: 'https://a.trycloudflare.com' })),
    ).toBe('https://a.trycloudflare.com');
  });

  it('끝 슬래시를 뗀다 — 훅 URL 을 이어 붙일 때 //api 가 되면 안 된다', () => {
    expect(
      resolvePublicBaseUrl(fakeConfig({ PUBLIC_BASE_URL: 'https://a.example.com/' })),
    ).toBe('https://a.example.com');
  });

  it('미설정이면 null', () => {
    expect(resolvePublicBaseUrl(fakeConfig({}))).toBeNull();
  });

  it('빈 문자열도 미설정이다 — .env 에 자리만 잡아 둔 경우 (8-1 교훈)', () => {
    expect(resolvePublicBaseUrl(fakeConfig({ PUBLIC_BASE_URL: '' }))).toBeNull();
    expect(resolvePublicBaseUrl(fakeConfig({ PUBLIC_BASE_URL: '   ' }))).toBeNull();
  });

  it('http(s) 가 아니면 미설정으로 친다 — 훅 URL 로 쓸 수 없다', () => {
    expect(resolvePublicBaseUrl(fakeConfig({ PUBLIC_BASE_URL: 'localhost:3000' }))).toBeNull();
  });
});
