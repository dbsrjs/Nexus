import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/features/chat/selection_controller.dart';

void main() {
  test('★ 고른 메시지를 클릭 순서가 아니라 시간순으로 돌려준다 - 이슈 원문이 대화의 첫 메시지가 되게', () {
    // 화면 목록은 서버가 준 최신순이다.
    const newestFirst = ['m3', 'm2', 'm1'];
    // 아래(최신)부터 위로 골랐다.
    expect(chronologicalSelection({'m3', 'm1'}, newestFirst), ['m1', 'm3']);
  });

  test('목록에 없는 id 는 버리지 않고 뒤에 둔다', () {
    expect(chronologicalSelection({'x', 'm1'}, const ['m2', 'm1']), ['m1', 'x']);
  });
}
