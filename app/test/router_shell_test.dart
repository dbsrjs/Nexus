import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/core/router.dart';

/// **셸 밖 화면에서 셸 안 라우트를 `push` 하면 앱이 죽는다.**
///
/// go_router 는 셸 페이지 키를 `ValueKey(route.hashCode)` 로 매긴다
/// (`go_router/src/match.dart`). `ShellRoute` 객체는 하나뿐이라 **언제나 같은
/// 키**이고, 셸이 이미 떠 있는데 셸 안 라우트를 `push` 하면 같은 키를 가진
/// 페이지가 둘이 되어 `!keyReservation.contains(key)` 로 죽는다. 최소 라우터로
/// 재현해 확인했다 — 셸 밖 → 셸 안 `push` 만 죽고, 셸 안 → 셸 안, 셸 안 →
/// 셸 밖, 그리고 셸 안으로 되돌아가는 `go` 는 모두 멀쩡하다.
///
/// **그 재현 자체는 커밋하지 않았다.** 프레임워크가 죽은 뒤 뒤따르는 예외가
/// 계속 새어 나와 테스트가 그것만으로 실패하고, 무엇보다 그것은 go_router 의
/// 동작이지 우리 코드가 아니다. 회귀를 막는 것은 아래 **구조 검사**다.
///
/// 이 결함은 2026-08-22 UI 리디자인이 `ShellRoute` 를 들이면서 들어왔다.
/// 그전에는 셸이 없어 같은 `push` 가 멀쩡했고, 그래서 10-3b 의 «파일을 눌러
/// 그 시점 전문» 은 당시 정상으로 확인됐다. **테스트가 없어 조용히 깨진 채로
/// 있었고, 11단계 화면 확인에서 사람이 눈으로 보고서야 드러났다.**
void main() {
  test('저장소 갈래는 셸 밖에 있다', () {
    final inShell = _pathsUnderShell(appRoutes());

    // 이 다섯은 서로를 `push` 로 오간다(PR 상세 → 파일, 커밋 상세 → 파일,
    // 탐색 → 커밋). 하나라도 셸 안에 있으면 그리로 들어가는 순간 죽는다.
    for (final path in const [
      '/s/:spaceId/repos/:repoId/browse',
      '/s/:spaceId/repos/:repoId/commits',
      '/s/:spaceId/repos/:repoId/commits/:sha',
      '/s/:spaceId/repos/:repoId/pulls',
      '/s/:spaceId/repos/:repoId/pulls/:number',
    ]) {
      expect(inShell, isNot(contains(path)), reason: '$path 가 셸 안에 있다');
    }
  });

  test('스레드와 커밋 이벤트도 셸 밖이다', () {
    final inShell = _pathsUnderShell(appRoutes());

    expect(inShell, isNot(contains('/s/:spaceId/c/:channelId/t/:messageId')));
    expect(inShell, isNot(contains('/s/:spaceId/repo-events/:eventId')));
  });

  test('머무는 갈래는 그대로 셸 안이다', () {
    // 반대쪽도 못 박는다 — 겁이 나서 전부 셸 밖으로 빼면 갈래를 옮길 때마다
    // 레일과 채널 목록이 다시 만들어져 리디자인이 없던 일이 된다.
    expect(
      _pathsUnderShell(appRoutes()),
      containsAll(<String>[
        '/s/:spaceId',
        '/s/:spaceId/issues',
        '/s/:spaceId/issues/:issueKey',
        '/s/:spaceId/sprints',
        '/s/:spaceId/files',
        '/s/:spaceId/repos',
        '/s/:spaceId/c/:channelId',
      ]),
    );
  });
}

/// `ShellRoute` 아래에 있는 라우트들의 **전체 경로**를 모은다.
Set<String> _pathsUnderShell(List<RouteBase> routes) {
  final found = <String>{};

  void walk(List<RouteBase> list, String prefix, bool inShell) {
    for (final route in list) {
      if (route is ShellRouteBase) {
        walk(route.routes, prefix, true);
        continue;
      }
      if (route is GoRoute) {
        // 자식 라우트의 path 는 상대 경로다. `/` 로 시작하면 절대 경로.
        final full = route.path.startsWith('/')
            ? route.path
            : '$prefix/${route.path}';
        if (inShell) found.add(full);
        walk(route.routes, full, inShell);
      }
    }
  }

  walk(routes, '', false);
  return found;
}
