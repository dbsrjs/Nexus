import { ConfigService } from '@nestjs/config';
import { resolveJwtSecrets } from './jwt.config';

/**
 * 시크릿 해석은 **부팅을 막는 안전장치**다. 약한 키로 조용히 뜨는 것이 최악이라
 * 미설정·과단축이면 프로세스를 중단시킨다 (docs/백엔드-설계.md §6).
 *
 * 여기서 잡으려는 회귀는 "누군가 편의를 위해 폴백 상수를 다시 넣는 것"이다.
 * 옛 코드에는 모듈마다 다른 폴백이 있어, JWT_SECRET 없이 뜨면 REST 는 되는데
 * 소켓만 전부 인증 실패하는 상태가 만들어졌다 (전환 계획 §3.5-1).
 */
function configOf(values: Record<string, string | undefined>): ConfigService {
  return {
    get: (key: string) => values[key],
  } as unknown as ConfigService;
}

const validSecret = 'a'.repeat(48);

describe('resolveJwtSecrets', () => {
  it('JWT_SECRET 이 없으면 부팅을 막는다', () => {
    expect(() => resolveJwtSecrets(configOf({}))).toThrow(/JWT_SECRET/);
  });

  it('빈 문자열·공백도 미설정으로 본다', () => {
    expect(() => resolveJwtSecrets(configOf({ JWT_SECRET: '' }))).toThrow();
    expect(() => resolveJwtSecrets(configOf({ JWT_SECRET: '   ' }))).toThrow();
  });

  it('32자 미만은 거부한다', () => {
    expect(() =>
      resolveJwtSecrets(configOf({ JWT_SECRET: 'a'.repeat(31) })),
    ).toThrow(/짧습니다/);
  });

  it('리프레시 시크릿을 지정하지 않으면 액세스 시크릿을 재사용한다', () => {
    const secrets = resolveJwtSecrets(configOf({ JWT_SECRET: validSecret }));
    expect(secrets.refreshSecret).toBe(validSecret);
  });

  it('리프레시 시크릿을 지정하면 분리한다 — 한쪽 유출이 다른 쪽으로 번지지 않는다', () => {
    const refresh = 'b'.repeat(48);
    const secrets = resolveJwtSecrets(
      configOf({ JWT_SECRET: validSecret, JWT_REFRESH_SECRET: refresh }),
    );
    expect(secrets.accessSecret).toBe(validSecret);
    expect(secrets.refreshSecret).toBe(refresh);
  });

  it('수명 기본값은 15분 / 7일', () => {
    const secrets = resolveJwtSecrets(configOf({ JWT_SECRET: validSecret }));
    expect(secrets.accessTtl).toBe('15m');
    expect(secrets.refreshTtl).toBe('7d');
  });
});
