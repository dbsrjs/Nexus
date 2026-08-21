import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/shared/markdown/plain_text.dart';

const _id = '11111111-1111-1111-1111-111111111111';

void main() {
  test('인라인 서식을 벗긴다', () {
    expect(toPlainText('**굵게** *기울임* ~~취소~~'), '굵게 기울임 취소');
  });

  test('코드 표기를 벗기되 내용은 남긴다', () {
    expect(toPlainText('`a()` 호출'), 'a() 호출');
  });

  test('멘션은 이름으로 남는다', () {
    expect(
      toPlainText('<@$_id> 님', names: const {_id: '이윤건'}),
      '@이윤건 님',
    );
  });

  test('링크는 글자만 남는다', () {
    expect(toPlainText('[문서](https://example.com)'), '문서');
  });

  test('블록 마커를 벗긴다', () {
    expect(toPlainText('# 제목'), '제목');
    expect(toPlainText('> 인용'), '인용');
    expect(toPlainText('- 하나\n- 둘'), '하나 둘');
  });

  test('코드블록은 한 줄로 접힌다', () {
    // 미리보기에 코드 열 줄이 펼쳐지면 안 된다.
    expect(
      toPlainText('```dart\nvar a = 1;\nvar b = 2;\n```'),
      'var a = 1; var b = 2;',
    );
  });

  test('표는 셀을 이어 붙인다', () {
    expect(toPlainText('| a | b |\n|---|---|\n| 1 | 2 |'), 'a b 1 2');
  });

  test('여러 줄이 한 줄이 된다', () {
    expect(toPlainText('첫 줄\n둘째 줄'), '첫 줄 둘째 줄');
  });

  test('서식이 없으면 그대로다', () {
    expect(toPlainText('평범한 문장'), '평범한 문장');
  });
}
