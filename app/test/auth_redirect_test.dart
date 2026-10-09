import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/core/auth_redirect.dart';
import 'package:nexus_app/core/env.dart';
import 'package:nexus_app/domain/models/user.dart';
import 'package:nexus_app/features/auth/auth_controller.dart';
import 'package:nexus_app/features/space/invite_code.dart';

/// 가려던 주소를 잃지 않는다(«마지막» 딥링크).
///
/// 예전 규칙은 토큰을 확인하는 동안 `/`, 확인되면 `/spaces` 였다 — 웹에서 새로고침하면
/// 늘 스페이스 고르기로 돌아갔다(진행 기록 «웹 확인»).
void main() {
  const restoring = AuthRestoring();
  const signedOut = AuthSignedOut();
  const signedIn = AuthSignedIn(
    User(id: 'u1', email: 'a@example.com', name: 'A'),
  );

  String? go(AuthState auth, String location) =>
      authRedirect(auth, Uri.parse(location));

  /// 상태가 바뀔 때마다 라우터가 하는 일 — 돌려준 주소로 옮겨 가 다시 묻는다.
  String settle(AuthState auth, String location) {
    var at = location;
    for (var i = 0; i < 5; i++) {
      final next = go(auth, at);
      if (next == null) return at;
      at = next;
    }
    fail('redirect 가 고리를 돈다: $location');
  }

  group('새로고침 — 토큰을 확인하는 동안', () {
    test('깊은 주소는 / 에서 from 으로 들고 기다린다', () {
      expect(go(restoring, '/s/sp1/c/ch1'), '/?from=%2Fs%2Fsp1%2Fc%2Fch1');
      expect(go(restoring, '/?from=%2Fs%2Fsp1'), isNull);
    });

    test('확인되면 그 주소로 돌아간다', () {
      final waiting = settle(restoring, '/s/sp1/c/ch1');
      expect(settle(signedIn, waiting), '/s/sp1/c/ch1');
    });

    test('쿼리도 함께 돌아간다', () {
      final waiting = settle(restoring, '/settings/account?from=%2Fs%2Fsp1');
      expect(settle(signedIn, waiting), '/settings/account?from=%2Fs%2Fsp1');
    });

    test('갈 곳 없이 켰으면 예전처럼 /spaces', () {
      expect(settle(signedIn, settle(restoring, '/')), '/spaces');
    });

    test('세션이 만료돼 있으면 로그인으로 가되 주소를 들고 간다', () {
      final waiting = settle(restoring, '/invite/abcdefgh1234');
      final login = settle(signedOut, waiting);
      expect(login, '/login?from=%2Finvite%2Fabcdefgh1234');
      // 로그인하면 링크로 돌아온다.
      expect(settle(signedIn, login), '/invite/abcdefgh1234');
    });
  });

  group('로그아웃 상태', () {
    test('로그인 · 가입 화면은 그대로', () {
      expect(go(signedOut, '/login'), isNull);
      expect(go(signedOut, '/signup'), isNull);
    });

    test('그 밖은 로그인으로, 원래 주소는 from 으로', () {
      expect(go(signedOut, '/s/sp1/issues'), '/login?from=%2Fs%2Fsp1%2Fissues');
    });

    test('/ 에서 왔으면 / 가 들고 있던 것을 넘긴다', () {
      expect(go(signedOut, '/?from=%2Fs%2Fsp1'), '/login?from=%2Fs%2Fsp1');
      expect(go(signedOut, '/'), '/login');
    });
  });

  group('from 은 앱 안의 주소만', () {
    test('바깥 주소로 튕기지 않는다', () {
      for (final evil in [
        '//evil.example/x',
        'https://evil.example',
        '/\\evil.example',
        'javascript:alert(1)',
        'evil',
      ]) {
        final login = '/login?from=${Uri.encodeQueryComponent(evil)}';
        expect(settle(signedIn, login), '/spaces', reason: evil);
      }
    });

    test('거쳐 가는 화면으로는 돌아가지 않는다(되돌이 고리)', () {
      expect(safeReturnPath('/login'), isNull);
      expect(safeReturnPath('/'), isNull);
      expect(safeReturnPath('/login?from=%2Fs'), isNull);
    });
  });

  test('로그인한 채 깊은 주소는 건드리지 않는다', () {
    expect(go(signedIn, '/s/sp1/c/ch1'), isNull);
    expect(go(signedIn, '/invite/abcdefgh1234'), isNull);
  });

  group('초대 링크', () {
    test('링크는 웹 주소의 해시 경로다', () {
      expect(
        Env.inviteLink('abcdefgh1234'),
        '${Env.webBase}/#/invite/abcdefgh1234',
      );
    });

    test('링크를 통째로 「초대 코드로 참여」에 붙여넣어도 코드를 읽는다', () {
      expect(
        parseInviteCode('https://nexus.example.com/#/invite/abcdefgh1234'),
        'abcdefgh1234',
      );
      expect(parseInviteCode(Env.inviteLink('abcdefgh1234')), 'abcdefgh1234');
    });
  });
}
