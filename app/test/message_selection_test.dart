import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/features/chat/selection_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  SelectionController ctrl() =>
      container.read(selectionControllerProvider.notifier);
  SelectionState state() => container.read(selectionControllerProvider);

  test('처음에는 선택 모드가 꺼져 있다', () {
    expect(state().active, isFalse);
    expect(state().count, 0);
  });

  test('start 하면 선택 모드가 켜지고 그 하나가 골라진다', () {
    ctrl().start('m-1');
    expect(state().active, isTrue);
    expect(state().ids, {'m-1'});
  });

  test('toggle 로 더 고른다', () {
    ctrl().start('m-1');
    ctrl().toggle('m-2');
    expect(state().count, 2);
  });

  test('이미 고른 것을 toggle 하면 빠진다', () {
    ctrl().start('m-1');
    ctrl().toggle('m-2');
    ctrl().toggle('m-2');
    expect(state().ids, {'m-1'});
  });

  test('★ 마지막 하나를 빼면 선택 모드가 저절로 꺼진다 - 빈 앱바가 남지 않는다', () {
    ctrl().start('m-1');
    ctrl().toggle('m-1');
    expect(state().active, isFalse);
    expect(state().count, 0);
  });

  test('clear 하면 선택 모드가 꺼진다', () {
    ctrl().start('m-1');
    ctrl().toggle('m-2');
    ctrl().clear();
    expect(state().active, isFalse);
    expect(state().ids, isEmpty);
  });

  test('★ 선택 모드가 꺼져 있을 때 toggle 은 아무것도 하지 않는다', () {
    ctrl().toggle('m-1');
    expect(state().active, isFalse);
    expect(state().count, 0);
  });
}
