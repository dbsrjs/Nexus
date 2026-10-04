import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/space.dart';
import 'package:nexus_app/features/space/members_controller.dart';

/// 16단계 설계 D7 — 서버의 `outranks` 를 그대로 비춘다. 눌러 봐야 실패할 동작을 보이지 않는다.
void main() {
  bool can(SpaceRole me, SpaceRole target, {bool self = false}) =>
      canManageMember(me: me, target: target, self: self);

  test('admin 은 member · guest 를 다룬다', () {
    expect(can(SpaceRole.admin, SpaceRole.member), isTrue);
    expect(can(SpaceRole.admin, SpaceRole.guest), isTrue);
  });
  test('admin 은 admin · owner 를 못 다룬다', () {
    expect(can(SpaceRole.admin, SpaceRole.admin), isFalse);
    expect(can(SpaceRole.admin, SpaceRole.owner), isFalse);
  });
  test('owner 는 admin 까지 다룬다', () => expect(can(SpaceRole.owner, SpaceRole.admin), isTrue));
  test('member 는 아무도 못 다룬다', () => expect(can(SpaceRole.member, SpaceRole.guest), isFalse));
  test('자기 자신은 못 다룬다', () {
    expect(can(SpaceRole.owner, SpaceRole.member, self: true), isFalse);
  });
  test('역할 이름', () {
    expect(roleLabel(SpaceRole.guest), '손님');
    expect(roleLabel(SpaceRole.owner), '소유자');
  });
}
