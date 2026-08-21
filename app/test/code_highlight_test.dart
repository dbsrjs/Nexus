import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/features/repo/code_highlight.dart';

/// 조각을 `종류:내용` 으로 펼쳐 비교하기 쉽게 만든다.
List<String> spans(String line) =>
    highlightLine(line).map((s) => '${s.kind.name}:${s.text}').toList();

void main() {
  test('평범한 코드는 한 조각이다', () {
    expect(spans('foo(bar)'), ['plain:foo(bar)']);
  });

  test('키워드를 집는다', () {
    expect(spans('const a'), ['keyword:const', 'plain: a']);
  });

  test('단어 일부는 키워드가 아니다', () {
    // `constant` 안의 `const` 를 칠하면 코드가 알록달록해진다.
    expect(spans('constant'), ['plain:constant']);
  });

  test('문자열을 집는다', () {
    expect(spans("a = 'hi'"), ['plain:a = ', 'string:\'hi\'']);
  });

  test('문자열 안의 주석 기호는 주석이 아니다', () {
    // 이 겹침이 하이라이터에서 가장 자주 틀리는 자리다.
    expect(spans("url = 'http://x'"), ['plain:url = ', "string:'http://x'"]);
  });

  test('주석 안의 따옴표는 문자열을 열지 않는다', () {
    expect(spans("// don't"), ["comment:// don't"]);
  });

  test('줄 주석은 줄 끝까지다', () {
    expect(spans('a = 1 // 설명'), [
      'plain:a = ',
      'number:1',
      'plain: ',
      'comment:// 설명',
    ]);
  });

  test('# 주석도 집는다 — 파이썬 · 셸', () {
    expect(spans('# 설명'), ['comment:# 설명']);
  });

  test('숫자를 집는다', () {
    // 끝에 빈 조각을 남기지 않는다.
    expect(spans('x = 42'), ['plain:x = ', 'number:42']);
  });

  test('식별자 안의 숫자는 숫자가 아니다', () {
    expect(spans('utf8'), ['plain:utf8']);
  });

  test('닫히지 않은 문자열은 줄 끝까지 문자열이다', () {
    // 여기서 멈추지 않으면 그 줄 전체가 엉뚱하게 칠해진다.
    expect(spans("a = 'hi"), ['plain:a = ', "string:'hi"]);
  });

  test('빈 줄은 조각이 없다', () {
    expect(spans(''), <String>[]);
  });

  test('블록 주석 시작은 줄 끝까지 주석으로 본다', () {
    // 여러 줄에 걸친 블록 주석은 추적하지 않는다 — 줄 단위 파서다.
    expect(spans('/* 설명'), ['comment:/* 설명']);
  });
}
