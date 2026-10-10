import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/shared/josa.dart';

void main() {
  test('한글 받침으로 고른다', () {
    expect(withJosa('일반', '을', '를'), '일반을');
    expect(withJosa('개발자', '을', '를'), '개발자를');
    expect(withJosa('메모', '이', '가'), '메모가');
  });

  test('「으로/로」 — ㄹ 받침 뒤에는 「로」', () {
    expect(withRo('서울'), '서울로');
    expect(withRo('부산'), '부산으로');
    expect(withRo('바다'), '바다로');
  });

  test('숫자는 읽는 소리로 본다', () {
    expect(withJosa('NEXUS-12', '을', '를'), 'NEXUS-12를');
    expect(withJosa('스프린트 3', '을', '를'), '스프린트 3을');
    expect(withRo('ab1'), 'ab1로');
  });

  test('영문 — 약어는 알파벳 이름, 낱말은 끝 글자', () {
    expect(withJosa('PR', '이', '가'), 'PR이');
    expect(withJosa('API', '이', '가'), 'API가');
    expect(withJosa('GitHub', '을', '를'), 'GitHub를');
    expect(withJosa('Kotlin', '을', '를'), 'Kotlin을');
  });
}
