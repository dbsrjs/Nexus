import {
  activeIdentities,
  canPublishNow,
  parseVoiceRoomName,
  sameIds,
  voiceRoomName,
} from './voice-room';

const S = '11111111-1111-4111-8111-111111111111';
const C = '22222222-2222-4222-8222-222222222222';

describe('voiceRoomName · parseVoiceRoomName', () => {
  it('되돌려 읽는다', () => {
    expect(parseVoiceRoomName(voiceRoomName(S, C))).toEqual({ spaceId: S, channelId: C });
  });

  it('우리가 만든 이름이 아니면 null — 다른 룸은 건드리지 않는다', () => {
    expect(parseVoiceRoomName('lobby')).toBeNull();
    expect(parseVoiceRoomName(`${S}:${C}:x`)).toBeNull();
    expect(parseVoiceRoomName(`${S}:not-a-uuid`)).toBeNull();
    expect(parseVoiceRoomName(undefined)).toBeNull();
    expect(parseVoiceRoomName('')).toBeNull();
  });
});

describe('activeIdentities', () => {
  it('JOINED · ACTIVE 만 센다 — 붙는 중(필드 없음 = JOINING) · 나가는 중은 빼고', () => {
    expect(
      activeIdentities([
        { identity: 'b', state: 'ACTIVE' },
        { identity: 'a', state: 'JOINED' },
        { identity: 'c' },
        { identity: 'd', state: 'DISCONNECTED' },
        { state: 'ACTIVE' },
      ]),
    ).toEqual(['a', 'b']);
  });

  it('같은 사람은 한 번만', () => {
    expect(
      activeIdentities([
        { identity: 'a', state: 'JOINED' },
        { identity: 'a', state: 'ACTIVE' },
      ]),
    ).toEqual(['a']);
  });
});

describe('canPublishNow', () => {
  it('snake_case(LiveKit 응답) · camelCase 를 모두 읽고, 없으면 false', () => {
    expect(canPublishNow({ permission: { can_publish: true } })).toBe(true);
    expect(canPublishNow({ permission: { canPublish: true } })).toBe(true);
    expect(canPublishNow({ permission: {} })).toBe(false);
    expect(canPublishNow({})).toBe(false);
  });
});

describe('sameIds', () => {
  it('정렬된 두 명단을 비교한다', () => {
    expect(sameIds(['a', 'b'], ['a', 'b'])).toBe(true);
    expect(sameIds(['a'], ['a', 'b'])).toBe(false);
    expect(sameIds([], [])).toBe(true);
  });
});
