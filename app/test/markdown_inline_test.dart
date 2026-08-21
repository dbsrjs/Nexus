import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/shared/markdown/inline.dart';

/// 트리를 `종류(내용)` 문자열로 펼친다 — 중첩까지 한눈에 비교한다.
String dump(List<InlineNode> nodes) => nodes
    .map((n) => n.children.isEmpty
        ? '${n.kind.name}(${n.text})'
        : '${n.kind.name}[${dump(n.children)}]')
    .join('+');

const _id = '11111111-1111-1111-1111-111111111111';

void main() {
  test('평범한 글은 한 조각이다', () {
    expect(dump(parseInline('안녕하세요')), 'text(안녕하세요)');
  });

  test('볼드', () {
    expect(dump(parseInline('a **b** c')), 'text(a )+bold[text(b)]+text( c)');
  });

  test('이탤릭 — 별표와 밑줄 둘 다', () {
    expect(dump(parseInline('*a*')), 'italic[text(a)]');
    expect(dump(parseInline('_a_')), 'italic[text(a)]');
  });

  test('취소선 · 스포일러', () {
    expect(dump(parseInline('~~a~~')), 'strike[text(a)]');
    expect(dump(parseInline('||a||')), 'spoiler[text(a)]');
  });

  test('인라인 코드', () {
    expect(dump(parseInline('`a`')), 'code(a)');
  });

  test('코드 안에서는 서식을 해석하지 않는다', () {
    // 인라인 코드의 존재 이유다.
    expect(dump(parseInline('`**a**`')), 'code(**a**)');
  });

  test('인라인끼리 중첩한다', () {
    expect(
      dump(parseInline('**a *b* c**')),
      'bold[text(a )+italic[text(b)]+text( c)]',
    );
  });

  test('닫히지 않은 서식은 글자 그대로다', () {
    // 사람이 ** 를 하나만 치는 일이 흔하다. 나머지가 통째로 굵어지면 안 된다.
    expect(dump(parseInline('**a')), 'text(**a)');
    expect(dump(parseInline('a ~~b')), 'text(a ~~b)');
  });

  test('볼드가 이탤릭보다 먼저다', () {
    // ** 를 * 두 개로 읽으면 빈 이탤릭이 된다.
    expect(dump(parseInline('**a**')), 'bold[text(a)]');
  });

  test('멘션은 이름으로 그린다', () {
    final nodes = parseInline('<@$_id> 님', names: const {_id: '이윤건'});

    expect(dump(nodes), 'mention(@이윤건)+text( 님)');
    expect(nodes.first.userId, _id);
  });

  test('이름을 모르면 @알 수 없음', () {
    // 원본 <@uuid> 를 그대로 보이면 사용자가 읽을 수 없다.
    expect(dump(parseInline('<@$_id>')), 'mention(@알 수 없음)');
  });

  test('@channel · @everyone 도 멘션이다', () {
    expect(
      dump(parseInline('@everyone 보세요')),
      'mention(@everyone)+text( 보세요)',
    );
  });

  test('메일 주소 안의 @channel 은 멘션이 아니다', () {
    expect(dump(parseInline('a@channel.com')), 'text(a@channel.com)');
  });

  test('멘션과 서식이 겹친다', () {
    final nodes = parseInline('**<@$_id>**', names: const {_id: '이윤건'});

    expect(dump(nodes), 'bold[mention(@이윤건)]');
  });

  test('코드 안의 멘션은 그대로 둔다', () {
    expect(dump(parseInline('`<@$_id>`')), 'code(<@$_id>)');
  });

  test('링크 — 대괄호 형식', () {
    final nodes = parseInline('[문서](https://example.com)');

    expect(dump(nodes), 'link[text(문서)]');
    expect(nodes.first.url, 'https://example.com');
  });

  test('맨몸 URL 도 링크가 된다', () {
    final nodes = parseInline('보기 https://example.com 끝');

    expect(nodes[1].kind, InlineKind.link);
    expect(nodes[1].url, 'https://example.com');
  });

  test('http · https 가 아닌 스킴은 링크가 아니다', () {
    // javascript: 가 웹 빌드에서 실행될 수 있다.
    expect(
      dump(parseInline('[x](javascript:alert(1))')),
      'text([x](javascript:alert(1)))',
    );
  });
}
