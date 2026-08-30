import { readPullNumber } from './pr-event';

describe('readPullNumber', () => {
  it('payload 의 number 를 읽는다 — GitHub 을 부르지 않는다', () => {
    expect(readPullNumber({ number: 12, pull_request: { title: 't' } })).toBe(12);
  });

  it('number 가 없으면 pull_request.number 를 본다', () => {
    expect(readPullNumber({ pull_request: { number: 7 } })).toBe(7);
  });

  it('둘 다 없으면 null 이다', () => {
    expect(readPullNumber({ pull_request: {} })).toBeNull();
    expect(readPullNumber(null)).toBeNull();
  });
});
