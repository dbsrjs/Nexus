import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/features/space/invite_code.dart';

/// 16단계 설계 D2 — 코드만 붙여넣든, 문장째 붙여넣든 끝의 12자를 읽는다.
void main() {
  test('코드만', () => expect(parseInviteCode('abcdefghjk23'), 'abcdefghjk23'));
  test('앞뒤 공백 · 줄바꿈', () => expect(parseInviteCode('  abcdefghjk23\n'), 'abcdefghjk23'));
  test('문장째', () {
    expect(parseInviteCode('Nexus 초대 코드: abcdefghjk23 (7일)'), 'abcdefghjk23');
  });
  test('대문자로 옮겨 적어도 읽는다', () => expect(parseInviteCode('ABCDEFGHJK23'), 'abcdefghjk23'));
  test('둘이면 마지막 것', () {
    expect(parseInviteCode('aaaaaaaaaaaa bbbbbbbbbbbb'), 'bbbbbbbbbbbb');
  });
  test('12자가 아니면 없다', () {
    expect(parseInviteCode('abc'), isNull);
    expect(parseInviteCode('abcdefghjk234'), isNull);
    expect(parseInviteCode(''), isNull);
  });
}
