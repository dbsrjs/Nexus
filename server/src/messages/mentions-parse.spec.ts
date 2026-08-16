import { parseMentions } from './mentions.service';

/**
 * 본문에서 멘션을 찾는 규칙.
 *
 * DB 동작은 `npm run check:mentions` 가 실서버로 확인한다. 여기서는 **문자열을
 * 어떻게 읽는가**만 고정한다 — 사람이 쓴 본문이 그대로 들어오므로 경계가 많다.
 */
describe('parseMentions', () => {
  const uuid = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';
  const other = 'a1b2c3d4-e5f6-4a5b-8c7d-9e0f1a2b3c4d';

  it('id 표기를 찾는다', () => {
    expect(parseMentions(`<@${uuid}> 안녕`).userIds).toEqual([uuid]);
  });

  it('★ 같은 사람을 여러 번 불러도 한 번으로 친다', () => {
    // 알림이 여러 개 갈 이유가 없다.
    expect(parseMentions(`<@${uuid}> 그리고 <@${uuid}>`).userIds).toEqual([uuid]);
  });

  it('여러 사람을 찾는다', () => {
    const parsed = parseMentions(`<@${uuid}> <@${other}>`);
    expect(parsed.userIds).toHaveLength(2);
    expect(parsed.userIds).toContain(other);
  });

  it('대문자로 쓴 id 도 같은 사람으로 본다', () => {
    expect(parseMentions(`<@${uuid.toUpperCase()}>`).userIds).toEqual([uuid]);
  });

  it('★ @이름 표기는 멘션이 아니다', () => {
    // 이름을 본문에 박으면 이름이 바뀔 때 낡고, 동명이인을 구분할 수 없으며,
    // 이름에 공백이 있으면 어디까지가 멘션인지 정할 수 없다.
    expect(parseMentions('@홍길동 안녕').userIds).toEqual([]);
  });

  it('id 모양이 아니면 무시한다', () => {
    expect(parseMentions('<@not-a-uuid> <@123>').userIds).toEqual([]);
  });

  it('빈 본문', () => {
    const parsed = parseMentions('');
    expect(parsed.userIds).toEqual([]);
    expect(parsed.channel).toBe(false);
    expect(parsed.everyone).toBe(false);
  });

  describe('@channel · @everyone', () => {
    it('문장 맨 앞', () => {
      expect(parseMentions('@channel 공지').channel).toBe(true);
      expect(parseMentions('@everyone 공지').everyone).toBe(true);
    });

    it('공백 뒤', () => {
      expect(parseMentions('여러분 @channel 보세요').channel).toBe(true);
    });

    it('★ 이메일 속 @channel 은 멘션이 아니다', () => {
      // 앞에 공백이 있어야 한다. 없으면 주소의 일부다.
      expect(parseMentions('name@channel.com 으로 보내라').channel).toBe(false);
      expect(parseMentions('x@everyone.io').everyone).toBe(false);
    });

    it('★ 더 긴 단어의 앞부분이면 멘션이 아니다', () => {
      // \\b 로 단어 경계를 요구한다.
      expect(parseMentions('@channels 는 복수형').channel).toBe(false);
    });

    it('둘 다 있으면 둘 다 찾는다 (덮어쓰기는 서비스가 정한다)', () => {
      const parsed = parseMentions('@everyone @channel');
      expect(parsed.everyone).toBe(true);
      expect(parsed.channel).toBe(true);
    });
  });

  it('사용자 멘션과 특수 멘션이 섞여도 각각 찾는다', () => {
    const parsed = parseMentions(`@channel 그리고 <@${uuid}> 확인 바랍니다`);
    expect(parsed.channel).toBe(true);
    expect(parsed.userIds).toEqual([uuid]);
  });
});
