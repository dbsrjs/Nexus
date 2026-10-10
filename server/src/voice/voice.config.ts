import { ConfigService } from '@nestjs/config';
import { envTrimmed } from '../config/env';

/** LiveKit 에 닿는 값 넷(20단계 설계 V3). */
export interface VoiceConfig {
  /** **앱이** 붙는 주소(ws:// · wss://). 토큰과 함께 앱에 준다. */
  url: string;
  /** **서버가** 서버 API(Twirp)를 부르는 주소. 배포에서는 컨테이너 안 주소(http://livekit:7880)다. */
  apiUrl: string;
  apiKey: string;
  apiSecret: string;
}

/** HS256 키 길이. LiveKit 도 짧은 시크릿을 거부한다 — 그보다 먼저 우리가 막는다. */
const MIN_SECRET_LENGTH = 32;

/**
 * `LIVEKIT_*` 를 읽는다. **셋(URL · 키 · 시크릿)이 모두 비면 통화가 꺼진 것**이고(null) 서버의
 * 나머지는 그대로 돈다 — AI(`LLM_PROVIDER`)와 같은 규칙이다. **일부만 차 있으면 부팅을 멈춘다** —
 * 반쯤 켜진 통화는 「들어가기」를 누른 순간에야 실패한다.
 */
export function resolveVoiceConfig(config: ConfigService): VoiceConfig | null {
  const url = envTrimmed(config, 'LIVEKIT_URL');
  const apiKey = envTrimmed(config, 'LIVEKIT_API_KEY');
  const apiSecret = envTrimmed(config, 'LIVEKIT_API_SECRET');
  if (!url && !apiKey && !apiSecret) return null;

  if (!url || !apiKey || !apiSecret) {
    throw new Error(
      'LIVEKIT_URL · LIVEKIT_API_KEY · LIVEKIT_API_SECRET 는 셋 다 채우거나 셋 다 비우십시오',
    );
  }
  if (!/^wss?:\/\//.test(url)) {
    throw new Error('LIVEKIT_URL 은 ws:// 또는 wss:// 로 시작해야 합니다');
  }
  if (apiSecret.length < MIN_SECRET_LENGTH) {
    throw new Error(`LIVEKIT_API_SECRET 은 ${MIN_SECRET_LENGTH}자 이상이어야 합니다`);
  }

  // 비우면 앱 주소에서 만든다 — 개발은 둘이 같다(ws://127.0.0.1:7880 → http://127.0.0.1:7880).
  const apiUrl = envTrimmed(config, 'LIVEKIT_API_URL') ?? url.replace(/^ws/, 'http');
  if (!/^https?:\/\//.test(apiUrl)) {
    throw new Error('LIVEKIT_API_URL 은 http:// 또는 https:// 로 시작해야 합니다');
  }

  // 끝 슬래시를 떼지 않으면 `{apiUrl}/twirp/...` 가 `//twirp` 가 된다.
  return {
    url: url.replace(/\/+$/, ''),
    apiUrl: apiUrl.replace(/\/+$/, ''),
    apiKey,
    apiSecret,
  };
}
