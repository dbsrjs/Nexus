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

  // selection_order_test.dart 에 따로 있던 것 — 같은 파일(selection_controller.dart)의
  // 순수 함수라 여기로 합쳤다.
  group('chronologicalSelection', () {
    test('★ 고른 메시지를 클릭 순서가 아니라 시간순으로 돌려준다 - 이슈 원문이 대화의 첫 메시지가 되게', () {
      // 화면 목록은 서버가 준 최신순이다.
      const newestFirst = ['m3', 'm2', 'm1'];
      // 아래(최신)부터 위로 골랐다.
      expect(chronologicalSelection({'m3', 'm1'}, newestFirst), ['m1', 'm3']);
    });

    test('목록에 없는 id 는 버리지 않고 뒤에 둔다', () {
      expect(chronologicalSelection({'x', 'm1'}, const ['m2', 'm1']), ['m1', 'x']);
    });
  });
}
