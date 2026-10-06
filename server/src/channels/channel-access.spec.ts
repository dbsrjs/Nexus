import { channelAccess } from './channel-access';

/** 16단계 설계 §2 — 채널 가시성 · 전송 판정의 유일한 자리. */
describe('channelAccess', () => {
  const hide = { canView: false, canSend: false };
  const readOnly = { canView: true, canSend: false };

  it('공개 채널 · 행 없음 → 보고 보낸다', () => {
    expect(channelAccess({ isPrivate: false, isMember: false, perm: null })).toEqual({
      view: true,
      send: true,
    });
  });

  it('★ 공개 채널에서 역할을 가리면 멤버 행이 있어도 못 본다(D23)', () => {
    // 공개 채널은 한 번 읽기만 해도 markRead 가 멤버 행을 만든다. 행이 이기면 가림이 듣지 않는다.
    expect(channelAccess({ isPrivate: false, isMember: true, perm: hide })).toEqual({
      view: false,
      send: false,
    });
    expect(channelAccess({ isPrivate: false, isMember: false, perm: hide })).toEqual({
      view: false,
      send: false,
    });
  });

  it('공개 채널 · 읽기 전용 → 보되 못 보낸다', () => {
    expect(channelAccess({ isPrivate: false, isMember: true, perm: readOnly })).toEqual({
      view: true,
      send: false,
    });
  });

  it('비공개 채널은 명단이 정한다', () => {
    expect(channelAccess({ isPrivate: true, isMember: false, perm: null })).toEqual({
      view: false,
      send: false,
    });
    expect(channelAccess({ isPrivate: true, isMember: true, perm: null })).toEqual({
      view: true,
      send: true,
    });
  });

  it('비공개 채널에서는 canView 행을 보지 않는다(D22) — canSend 만 듣는다', () => {
    expect(channelAccess({ isPrivate: true, isMember: true, perm: hide })).toEqual({
      view: true,
      send: false,
    });
    expect(channelAccess({ isPrivate: true, isMember: true, perm: readOnly })).toEqual({
      view: true,
      send: false,
    });
  });

  it('★ 상대가 떠난 DM 은 보되 못 보낸다(17단계 D8)', () => {
    expect(
      channelAccess({
        isPrivate: true,
        isMember: true,
        perm: null,
        dmPeerPresent: false,
      }),
    ).toEqual({ view: true, send: false });
    expect(
      channelAccess({ isPrivate: true, isMember: true, perm: null, dmPeerPresent: true }),
    ).toEqual({ view: true, send: true });
  });
});
