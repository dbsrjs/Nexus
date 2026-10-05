import { BadRequestException, HttpException, UnauthorizedException } from '@nestjs/common';
import * as argon2 from 'argon2';
import { AuthService, isReservedEmail } from './auth.service';

const PASSWORD = 'right-password-1';

async function setup() {
  const passwordHash = await argon2.hash(PASSWORD);
  const prisma = {
    user: {
      findUnique: jest.fn().mockResolvedValue({ id: 'u-1', email: 'a@x.io', passwordHash }),
      create: jest.fn(),
    },
  };
  const refreshTokens = {
    startFamily: jest.fn(() => ({ id: 'r-1', familyId: 'f-1', expiresAt: new Date() })),
    persist: jest.fn(),
  };
  const jwt = { signAsync: jest.fn().mockResolvedValue('signed') };
  const config = { get: (key: string) => (key === 'JWT_SECRET' ? 'x'.repeat(40) : undefined) };
  const service = new AuthService(
    prisma as never,
    jwt as never,
    refreshTokens as never,
    config as never,
  );
  return { service, prisma };
}

describe('isReservedEmail', () => {
  it.each([
    ['github@bot.nexus.invalid', true],
    ['GitLab@Bot.Nexus.INVALID', true],
    ['x@invalid', true],
    ['someone@example.com', false],
    // 이름에 invalid 가 들어간 실제 도메인은 막지 않는다.
    ['a@invalid.example.com', false],
    ['a@notinvalid', false],
  ])('%s → %s', (email, reserved) => {
    expect(isReservedEmail(email)).toBe(reserved);
  });
});

describe('AuthService — 가입 · 로그인 보강', () => {
  it('★ 봇이 쓰는 예약 도메인(.invalid)으로는 가입할 수 없다', async () => {
    const { service, prisma } = await setup();
    await expect(
      service.signup('github@bot.nexus.invalid', 'long-password-1', 'GitHub'),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.user.create).not.toHaveBeenCalled();
  });

  it('★ 같은 주소 · 같은 이메일로 10번 틀리면 맞는 비밀번호도 429 다', async () => {
    const { service } = await setup();
    const client = { ip: '10.0.0.1' };
    for (let i = 0; i < 10; i++) {
      await expect(service.login('a@x.io', 'wrong-password', client)).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    }

    const blocked = service.login('a@x.io', PASSWORD, client);
    await expect(blocked).rejects.toBeInstanceOf(HttpException);
    await blocked.catch((err: HttpException) => {
      expect(err.getStatus()).toBe(429);
      // 전역 필터가 이 값을 Retry-After 헤더로 옮긴다.
      expect((err.getResponse() as { retryAfter: number }).retryAfter).toBeGreaterThan(0);
    });
  });

  it('다른 주소에서는 막히지 않는다 — 남이 내 이메일로 틀려도 나는 잠기지 않는다', async () => {
    const { service } = await setup();
    for (let i = 0; i < 10; i++) {
      await service.login('a@x.io', 'wrong-password', { ip: '10.0.0.1' }).catch(() => undefined);
    }
    await expect(service.login('a@x.io', PASSWORD, { ip: '10.0.0.2' })).resolves.toMatchObject({
      accessToken: 'signed',
    });
  });

  it('성공하면 실패 기록이 지워진다 — 오타 몇 번이 쌓여 잠기지 않는다', async () => {
    const { service } = await setup();
    const client = { ip: '10.0.0.1' };
    for (let i = 0; i < 9; i++) {
      await service.login('a@x.io', 'wrong-password', client).catch(() => undefined);
    }
    await service.login('a@x.io', PASSWORD, client);
    for (let i = 0; i < 9; i++) {
      await service.login('a@x.io', 'wrong-password', client).catch(() => undefined);
    }
    await expect(service.login('a@x.io', PASSWORD, client)).resolves.toMatchObject({
      accessToken: 'signed',
    });
  });
});
