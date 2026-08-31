import { readPullNumber } from './pr-event';

describe('readPullNumber', () => {
  it('감싼 payload 에서 raw.number 를 읽는다 — GitHub 을 부르지 않는다', () => {
    expect(
      readPullNumber({
        deliveryId: 'd1',
        event: 'pull_request',
        raw: { number: 12, pull_request: { title: 't' } },
      }),
    ).toBe(12);
  });

  it('raw.number 가 없으면 raw.pull_request.number 를 본다', () => {
    expect(
      readPullNumber({
        deliveryId: 'd2',
        event: 'pull_request',
        raw: { pull_request: { number: 7 } },
      }),
    ).toBe(7);
  });

  it('raw 안에 둘 다 없으면 null 이다', () => {
    expect(
      readPullNumber({ deliveryId: 'd3', event: 'pull_request', raw: { pull_request: {} } }),
    ).toBeNull();
    expect(readPullNumber({ deliveryId: 'd4', event: 'pull_request', raw: {} })).toBeNull();
  });

  it('raw 가 없거나 payload 자체가 없으면 null 이다', () => {
    expect(readPullNumber({ deliveryId: 'd5', event: 'pull_request' })).toBeNull();
    expect(readPullNumber(null)).toBeNull();
    expect(readPullNumber(undefined)).toBeNull();
    expect(readPullNumber('not an object')).toBeNull();
  });
});
