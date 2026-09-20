import { buildTranscript, TranscriptMessage } from './transcript';

const at = (h: number, m: number) => new Date(Date.UTC(2026, 8, 20, h, m));

function msg(over: Partial<TranscriptMessage> = {}): TranscriptMessage {
  return {
    body: '안녕하세요',
    deletedAt: null,
    createdAt: at(1, 5),
    authorName: '가영',
    attachmentNames: [],
    ...over,
  };
}

describe('buildTranscript', () => {
  it('[시각] 이름: 본문 한 줄씩으로 만든다', () => {
    const out = buildTranscript([msg()], new Map());
    expect(out).toBe('[01:05] 가영: 안녕하세요');
  });

  it('여러 줄을 줄바꿈으로 잇는다', () => {
    const out = buildTranscript(
      [msg({ body: '첫째' }), msg({ body: '둘째', authorName: '나영' })],
      new Map(),
    );
    expect(out).toBe('[01:05] 가영: 첫째\n[01:05] 나영: 둘째');
  });

  it('<@id> 를 표시 이름으로 되돌린다 — LLM 에 UUID 를 읽히지 않는다', () => {
    const out = buildTranscript(
      [msg({ body: '<@u-1> 확인 부탁해요' })],
      new Map([['u-1', '다영']]),
    );
    expect(out).toBe('[01:05] 가영: @다영 확인 부탁해요');
  });

  it('모르는 id 는 @(알 수 없음) 으로 둔다 — 원문을 잃게 하지 않는다', () => {
    const out = buildTranscript([msg({ body: '<@u-9> 님' })], new Map());
    expect(out).toBe('[01:05] 가영: @(알 수 없음) 님');
  });

  it('한 줄에 여러 멘션을 모두 바꾼다', () => {
    const out = buildTranscript(
      [msg({ body: '<@u-1> <@u-2> 회의' })],
      new Map([
        ['u-1', '다영'],
        ['u-2', '라영'],
      ]),
    );
    expect(out).toBe('[01:05] 가영: @다영 @라영 회의');
  });

  it('소프트 삭제된 메시지는 본문을 싣지 않는다 (판단 #5)', () => {
    const out = buildTranscript(
      [msg({ body: '지워진 원문', deletedAt: at(2, 0) })],
      new Map(),
    );
    expect(out).toBe('[01:05] 가영: (삭제된 메시지)');
    expect(out).not.toContain('지워진 원문');
  });

  it('첨부는 파일명만 싣는다 — 바이트를 LLM 에 보내지 않는다', () => {
    const out = buildTranscript(
      [msg({ body: '이것 봐요', attachmentNames: ['설계.png', '표.csv'] })],
      new Map(),
    );
    expect(out).toBe('[01:05] 가영: 이것 봐요 (첨부: 설계.png, 표.csv)');
  });

  it('본문이 비고 첨부만 있어도 첨부가 보인다', () => {
    const out = buildTranscript(
      [msg({ body: '', attachmentNames: ['a.png'] })],
      new Map(),
    );
    expect(out).toBe('[01:05] 가영: (첨부: a.png)');
  });

  it('마크다운 원문을 그대로 둔다 — 벗기면 코드블록이 망가진다', () => {
    const body = '이렇게요\n```ts\nconst a = 1;\n```';
    const out = buildTranscript([msg({ body })], new Map());
    expect(out).toContain('```ts');
    expect(out).toContain('const a = 1;');
  });
});
