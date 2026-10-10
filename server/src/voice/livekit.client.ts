import { createHash, timingSafeEqual } from 'node:crypto';
import { JwtService } from '@nestjs/jwt';
import type { VoiceConfig } from './voice.config';
import type { LiveKitParticipant } from './voice-room';

/** 앱이 받은 토큰으로 들어갈 수 있는 시간. 들어간 뒤에는 LiveKit 이 연결을 스스로 이어 간다. */
export const VOICE_TOKEN_TTL_SEC = 15 * 60;
/** 서버 API 를 부를 때 쓰는 토큰. 한 번 부르고 버린다. */
const ADMIN_TOKEN_TTL_SEC = 60;
/** 서버 API 한 번의 시간 제한. LiveKit 이 멈춰도 요청 하나가 붙잡히지 않게. */
const API_TIMEOUT_MS = 5000;

/**
 * 마이크와 화면 공유만 — **카메라는 범위 밖이다**(보스 결정, 2026-10-10). 토큰에 없으면 앱을
 * 고쳐도 카메라 트랙을 올릴 수 없다.
 */
export const PUBLISH_SOURCES = [
  'microphone',
  'screen_share',
  'screen_share_audio',
] as const;

/**
 * LiveKit 과 말하는 세 가지 — 접속 토큰 · 서버 API(Twirp) · 웹훅 서명. **SDK 를 들이지 않는다**
 * (CLAUDE.md §3-8): 셋 다 HS256 JWT 와 JSON POST 라 `@nestjs/jwt` 와 `fetch` 로 충분하고,
 * 실제 LiveKit(v1.9.1)에 대고 확인했다(20단계 설계 V5).
 */
export class LiveKitClient {
  constructor(
    private readonly config: VoiceConfig,
    private readonly jwt: JwtService,
  ) {}

  get url(): string {
    return this.config.url;
  }

  /** 룸 하나에 들어가는 토큰. `canPublish` 가 거짓이면 듣기만 한다. */
  joinToken(input: {
    room: string;
    identity: string;
    name: string;
    canPublish: boolean;
  }): Promise<string> {
    return this.sign(
      {
        name: input.name,
        video: {
          roomJoin: true,
          room: input.room,
          canSubscribe: true,
          canPublish: input.canPublish,
          canPublishSources: input.canPublish ? [...PUBLISH_SOURCES] : [],
          // 데이터 채널 · 메타데이터는 쓰지 않는다 — 열어 두면 앱을 고친 사람이 룸 안에서
          // 우리가 검사하지 않는 말을 주고받는다.
          canPublishData: false,
          canUpdateOwnMetadata: false,
        },
      },
      VOICE_TOKEN_TTL_SEC,
      input.identity,
    );
  }

  /**
   * 웹훅이 정말 LiveKit 에서 왔는가. `Authorization` 은 **Bearer 없이** JWT 그대로이고,
   * 그 `sha256` 주장이 원문 바이트의 SHA-256(base64)이다 — 파싱한 객체를 다시 직렬화하면
   * 틀린다(CLAUDE.md §3-14 와 같은 이유).
   */
  async verifyWebhook(raw: Buffer, auth: string | undefined): Promise<boolean> {
    if (!auth) return false;
    let claims: { sha256?: unknown; exp?: unknown };
    try {
      claims = await this.jwt.verifyAsync(auth.replace(/^Bearer\s+/i, ''), {
        secret: this.config.apiSecret,
        issuer: this.config.apiKey,
        algorithms: ['HS256'],
      });
    } catch {
      return false;
    }
    // 만료가 없는 토큰은 서명이 맞아도 영원히 통한다 — LiveKit 이 만드는 토큰은 늘 exp 가 있다.
    if (typeof claims.exp !== 'number' || typeof claims.sha256 !== 'string') return false;
    const expected = createHash('sha256').update(raw).digest();
    const given = Buffer.from(claims.sha256, 'base64');
    return given.length === expected.length && timingSafeEqual(given, expected);
  }

  async listRooms(): Promise<string[]> {
    const res = await this.call<{ rooms?: { name?: string }[] }>(
      'ListRooms',
      {},
      { roomList: true },
    );
    return (res.rooms ?? []).map((r) => r.name ?? '').filter(Boolean);
  }

  async listParticipants(room: string): Promise<LiveKitParticipant[]> {
    const res = await this.call<{ participants?: LiveKitParticipant[] }>(
      'ListParticipants',
      { room },
      { roomAdmin: true, room },
    );
    return res.participants ?? [];
  }

  async removeParticipant(room: string, identity: string): Promise<void> {
    await this.call('RemoveParticipant', { room, identity }, { roomAdmin: true, room });
  }

  /** 말하기 권한만 바꾼다 — 듣기는 그대로 둔다. */
  async setCanPublish(
    room: string,
    identity: string,
    canPublish: boolean,
  ): Promise<void> {
    await this.call(
      'UpdateParticipant',
      {
        room,
        identity,
        permission: {
          can_subscribe: true,
          can_publish: canPublish,
          can_publish_data: false,
          can_publish_sources: canPublish
            ? PUBLISH_SOURCES.map((s) => s.toUpperCase())
            : [],
        },
      },
      { roomAdmin: true, room },
    );
  }

  private async call<T>(
    method: string,
    body: unknown,
    grant: Record<string, unknown>,
  ): Promise<T> {
    const token = await this.sign({ video: grant }, ADMIN_TOKEN_TTL_SEC);
    const res = await fetch(`${this.config.apiUrl}/twirp/livekit.RoomService/${method}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(API_TIMEOUT_MS),
    });
    if (!res.ok) {
      // 본문은 로그에만 쓰인다(호출하는 쪽이 잡는다). 응답으로 흘리지 않는다.
      throw new Error(
        `LiveKit ${method} ${res.status}: ${(await res.text()).slice(0, 200)}`,
      );
    }
    return (await res.json()) as T;
  }

  private sign(payload: object, ttlSec: number, subject?: string): Promise<string> {
    return this.jwt.signAsync(payload, {
      secret: this.config.apiSecret,
      issuer: this.config.apiKey,
      expiresIn: ttlSec,
      notBefore: 0,
      algorithm: 'HS256',
      ...(subject ? { subject } : {}),
    });
  }
}
