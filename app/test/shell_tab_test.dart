import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/features/shell/app_shell.dart';

/// 모바일 탭 줄은 고른 탭을 들고 있지 않고 경로에서 읽는다.
void main() {
  test('셸 안 경로마다 제 탭이 켜진다', () {
    expect(shellTabFor('/s/a'), 0);
    expect(shellTabFor('/s/a/c/ch1'), 0);
    expect(shellTabFor('/s/a/issues'), 2);
    expect(shellTabFor('/s/a/repos'), 4);
    expect(shellTabFor('/s/a/files'), 3);
  });

  test('★ 스프린트는 이슈 탭이다 - 「대화」 탭이 켜져 있었다', () {
    expect(shellTabFor('/s/a/sprints'), 2);
  });
}
