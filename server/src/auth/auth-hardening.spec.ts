import {
  BadRequestException,
  HttpException,
  UnauthorizedException,
} from '@nestjs/common';
import * as argon2 from 'argon2';
import {
  AuthService,
  isReservedEmail,
  resolveSignupLimit,
  SIGNUP_DEFAULT_LIMIT_PER_HOUR,
} from './auth.service';

const PASSWORD = 'right-password-1';

async function setup(env: Record<string, string> = {}) {
  const passwordHash = await argon2.hash(PASSWORD);
  const prisma = {
    user: {
      findUnique: jest
        .fn()
        .mockResolvedValue({ id: 'u-1', email: 'a@x.io', passwordHash }),
      create: jest.fn(),
    },
  };
  const refreshTokens = {
    startFamily: jest.fn(() => ({ id: 'r-1', familyId: 'f-1', expiresAt: new Date() })),
    persist: jest.fn(),
  };
  const jwt = { signAsync: jest.fn().mockResolvedValue('signed') };
  const config = {
    get: (key: string) => (key === 'JWT_SECRET' ? 'x'.repeat(40) : env[key]),
  };
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

describe('가입 시도 한도', () => {
  const config = (value?: string) => ({ get: () => value }) as never;

  it('비우면 기본값, 0 은 끔, 숫자가 아니면 기본값', () => {
    expect(resolveSignupLimit(config())).toBe(SIGNUP_DEFAULT_LIMIT_PER_HOUR);
    expect(resolveSignupLimit(config(''))).toBe(SIGNUP_DEFAULT_LIMIT_PER_HOUR);
    expect(resolveSignupLimit(config('0'))).toBe(0);
    expect(resolveSignupLimit(config('3'))).toBe(3);
    expect(resolveSignupLimit(config('lots'))).toBe(SIGNUP_DEFAULT_LIMIT_PER_HOUR);
  });

  it('★ 한 주소에서 한도만큼 시도하면 다음은 429 — 이미 가입된 이메일(409)도 센다', async () => {
    const { service, prisma } = await setup({ SIGNUP_LIMIT_PER_HOUR: '2' });
    const client = { ip: '10.0.0.1' };
    // setup 의 findUnique 는 늘 사용자를 돌려준다 — 두 번 다 409 다.
    for (let i = 0; i < 2; i++) {
      await expect(
        service.signup(`n${i}@x.io`, 'long-password-1', 'N', client),
      ).rejects.toMatchObject({ status: 409 });
    }
    const blocked = service.signup('n9@x.io', 'long-password-1', 'N', client);
    await expect(blocked).rejects.toBeInstanceOf(HttpException);
    await blocked.catch((err: HttpException) => {
      expect(err.getStatus()).toBe(429);
      expect((err.getResponse() as { retryAfter: number }).retryAfter).toBeGreaterThan(0);
    });
    // 막힌 시도는 DB 에 닿지 않는다.
    expect(prisma.user.findUnique).toHaveBeenCalledTimes(2);

    // 다른 주소는 따로 센다.
    await expect(
      service.signup('n8@x.io', 'long-password-1', 'N', { ip: '10.0.0.2' }),
    ).rejects.toMatchObject({ status: 409 });
  });

  it('0 이면 세지 않는다 — 개발 · CI 의 계약 검증이 한 주소에서 계정을 많이 만든다', async () => {
    const { service } = await setup({ SIGNUP_LIMIT_PER_HOUR: '0' });
    for (let i = 0; i < 30; i++) {
      await expect(
        service.signup(`n${i}@x.io`, 'long-password-1', 'N', { ip: '10.0.0.1' }),
      ).rejects.toMatchObject({ status: 409 });
    }
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
      await expect(
        service.login('a@x.io', 'wrong-password', client),
      ).rejects.toBeInstanceOf(UnauthorizedException);
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
      await service
        .login('a@x.io', 'wrong-password', { ip: '10.0.0.1' })
        .catch(() => undefined);
    }
    await expect(
      service.login('a@x.io', PASSWORD, { ip: '10.0.0.2' }),
    ).resolves.toMatchObject({
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
