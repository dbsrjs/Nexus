import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/shared/widgets/nexus_avatar.dart';

/// 아바타 색 칸은 플랫폼마다 같아야 한다.
void main() {
  test('★ 같은 seed 는 어느 플랫폼에서든 같은 칸 - String.hashCode 라 웹과 Android 가 달랐다', () {
    // 기댓값은 같은 계산을 브라우저 JS 로 따로 돌려 얻었다 — 웹의 수 체계에서도 같다는 확인이다.
    expect(avatarSlot('u1', 8), 4);
    expect(avatarSlot('34c7f499-6531-46f1-a949-dff858b041d1', 8), 5);
    expect(avatarSlot('디자인', 8), 4);
  });

  test('칸은 언제나 범위 안', () {
    for (final s in ['', 'a', 'x' * 500, '🙂🙂']) {
      expect(avatarSlot(s, 8), inInclusiveRange(0, 7));
    }
  });
}
