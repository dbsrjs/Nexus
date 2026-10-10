import { createHash } from 'node:crypto';
import { JwtService } from '@nestjs/jwt';
import { LiveKitClient, PUBLISH_SOURCES } from './livekit.client';

const config = {
  url: 'ws://127.0.0.1:7880',
  apiUrl: 'http://127.0.0.1:7880',
  apiKey: 'devkey',
  apiSecret: 's'.repeat(40),
};
const jwt = new JwtService({});
const client = new LiveKitClient(config, jwt);

/** LiveKit 이 웹훅에 붙이는 것과 같은 모양 — Bearer 없는 JWT, sha256 은 원문의 base64. */
function hookAuth(body: string, opts: { secret?: string; exp?: boolean } = {}) {
  const sha256 = createHash('sha256').update(body).digest('base64');
  return jwt.sign(
    { sha256 },
    {
      secret: opts.secret ?? config.apiSecret,
      issuer: config.apiKey,
      ...(opts.exp === false ? {} : { expiresIn: 60 }),
    },
  );
}

describe('LiveKitClient.joinToken', () => {
  it('룸 · identity · 이름을 싣고, 말하기는 마이크 · 화면 공유만 연다(카메라 없음)', async () => {
    const token = await client.joinToken({
      room: 'r',
      identity: 'u1',
      name: '보스',
      canPublish: true,
    });
    const claims = jwt.verify(token, { secret: config.apiSecret });
    expect(claims).toMatchObject({
      iss: 'devkey',
      sub: 'u1',
      name: '보스',
      video: {
        roomJoin: true,
        room: 'r',
        canSubscribe: true,
        canPublish: true,
        canPublishSources: [...PUBLISH_SOURCES],
        canPublishData: false,
      },
    });
    expect(PUBLISH_SOURCES).not.toContain('camera');
    expect(claims.exp - claims.nbf).toBeLessThanOrEqual(15 * 60);
  });

  it('말할 수 없으면 canPublish 가 거짓이다', async () => {
    const token = await client.joinToken({
      room: 'r',
      identity: 'u1',
      name: 'x',
      canPublish: false,
    });
    expect(jwt.verify(token, { secret: config.apiSecret }).video.canPublish).toBe(false);
  });
});

describe('LiveKitClient.verifyWebhook', () => {
  const body = '{"event":"room_started","room":{"name":"x"}}';

  it('원문 바이트의 해시가 맞으면 통과한다(Bearer 가 붙어 와도)', async () => {
    expect(await client.verifyWebhook(Buffer.from(body), hookAuth(body))).toBe(true);
    expect(
      await client.verifyWebhook(Buffer.from(body), `Bearer ${hookAuth(body)}`),
    ).toBe(true);
  });

  it('본문이 한 글자라도 다르면 거부한다 — 다시 직렬화한 본문도 마찬가지', async () => {
    const auth = hookAuth(body);
    expect(await client.verifyWebhook(Buffer.from(body + ' '), auth)).toBe(false);
    expect(
      await client.verifyWebhook(
        Buffer.from(JSON.stringify(JSON.parse(body), null, 1)),
        auth,
      ),
    ).toBe(false);
  });

  it('헤더가 없거나 · 다른 시크릿이거나 · 만료가 없으면 거부한다', async () => {
    expect(await client.verifyWebhook(Buffer.from(body), undefined)).toBe(false);
    expect(
      await client.verifyWebhook(
        Buffer.from(body),
        hookAuth(body, { secret: 'x'.repeat(40) }),
      ),
    ).toBe(false);
    expect(
      await client.verifyWebhook(Buffer.from(body), hookAuth(body, { exp: false })),
    ).toBe(false);
  });
});
