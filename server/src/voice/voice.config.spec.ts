import { ConfigService } from '@nestjs/config';
import { resolveVoiceConfig } from './voice.config';

function fakeConfig(values: Record<string, string>): ConfigService {
  return { get: (key: string) => values[key] } as unknown as ConfigService;
}

const SECRET = 's'.repeat(32);
const full = {
  LIVEKIT_URL: 'wss://rtc.example.com/',
  LIVEKIT_API_KEY: 'key',
  LIVEKIT_API_SECRET: SECRET,
};

describe('resolveVoiceConfig', () => {
  it('셋 다 비면 통화가 꺼진다(null) — 서버는 그대로 뜬다', () => {
    expect(resolveVoiceConfig(fakeConfig({}))).toBeNull();
    expect(
      resolveVoiceConfig(
        fakeConfig({ LIVEKIT_URL: ' ', LIVEKIT_API_KEY: '', LIVEKIT_API_SECRET: '' }),
      ),
    ).toBeNull();
  });

  it('일부만 차 있으면 부팅을 멈춘다 — 반쯤 켜진 통화는 누른 순간에야 실패한다', () => {
    expect(() => resolveVoiceConfig(fakeConfig({ LIVEKIT_URL: 'ws://x' }))).toThrow();
    expect(() =>
      resolveVoiceConfig(fakeConfig({ ...full, LIVEKIT_API_SECRET: '' })),
    ).toThrow();
  });

  it('API 주소를 비우면 앱 주소에서 만들고, 끝 슬래시를 뗀다', () => {
    expect(resolveVoiceConfig(fakeConfig(full))).toEqual({
      url: 'wss://rtc.example.com',
      apiUrl: 'https://rtc.example.com',
      apiKey: 'key',
      apiSecret: SECRET,
    });
  });

  it('API 주소를 따로 줄 수 있다 — 배포는 컨테이너 안 주소다', () => {
    expect(
      resolveVoiceConfig(fakeConfig({ ...full, LIVEKIT_API_URL: 'http://livekit:7880/' }))
        ?.apiUrl,
    ).toBe('http://livekit:7880');
  });

  it('ws(s) 가 아닌 앱 주소 · http(s) 가 아닌 API 주소 · 짧은 시크릿은 거부한다', () => {
    expect(() =>
      resolveVoiceConfig(fakeConfig({ ...full, LIVEKIT_URL: 'https://x' })),
    ).toThrow();
    expect(() =>
      resolveVoiceConfig(fakeConfig({ ...full, LIVEKIT_API_URL: 'livekit:7880' })),
    ).toThrow();
    expect(() =>
      resolveVoiceConfig(fakeConfig({ ...full, LIVEKIT_API_SECRET: 'short' })),
    ).toThrow();
  });
});
