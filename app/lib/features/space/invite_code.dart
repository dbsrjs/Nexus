/// 붙여넣은 글에서 초대 코드를 읽는다(16단계 설계 D2).
///
/// 코드는 서버가 만든 **영소문자 · 숫자 12자**다(`generateInviteCode`). 메신저로 받은
/// 문장을 통째로 붙여넣어도 되게, 영숫자가 아닌 글자로 자른 조각 중 **마지막 12자**를 쓴다.
/// 딥링크는 «마지막» 단계라 여기서는 주소를 해석하지 않는다.
String? parseInviteCode(String input) {
  final tokens = input
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.length == 12);
  return tokens.isEmpty ? null : tokens.last;
}
