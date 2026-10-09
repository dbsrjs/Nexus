import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/data/repositories/workspace_repository.dart';
import 'package:nexus_app/domain/models/space.dart';
import 'package:nexus_app/domain/models/user.dart';
import 'package:nexus_app/features/auth/auth_controller.dart';
import 'package:nexus_app/features/space/space_controller.dart';
import 'package:nexus_app/features/space/space_picker_screen.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/nx_host.dart';

/// 배포 전 정리(«마지막» 5) — 멤버가 아닌 스페이스 주소 · 스페이스 고르기의 로그아웃.
void main() {
  group('isConfirmedOutsider', () {
    test('★ 서버가 준 목록에 없으면 바깥사람이다', () async {
      final repo = _FakeWorkspace(online: true, spaces: [_space('mine')]);
      expect(await isConfirmedOutsider(repo, 'theirs'), isTrue);
      expect(await isConfirmedOutsider(repo, 'mine'), isFalse);
    });

    test('★ 서버에 못 닿으면 모르는 것이다 — 캐시에 없어도 내보내지 않는다', () async {
      final repo = _FakeWorkspace(online: false, spaces: const []);
      expect(await isConfirmedOutsider(repo, 'mine'), isFalse);
    });

    test('판정은 서버에 물은 뒤의 목록으로 한다 — 묻기 전 캐시가 아니다', () async {
      // 방금 참여해 캐시에는 아직 없고 서버에는 있다.
      final repo = _FakeWorkspace(
        online: true,
        spaces: const [],
        afterRefresh: [_space('joined')],
      );
      expect(await isConfirmedOutsider(repo, 'joined'), isFalse);
      expect(repo.refreshed, 1);
    });
  });

  group('스페이스 고르기', () {
    testWidgets('★ 스페이스가 없어도 계정과 로그아웃이 있다', (tester) async {
      final auth = _FakeAuth();
      final router = GoRouter(
        initialLocation: '/spaces',
        routes: [
          GoRoute(
            path: '/spaces',
            builder: (_, _) => const SpacePickerScreen(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => auth),
            spacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: nxTestApp(router: router),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('new@example.com'), findsOneWidget);
      await tester.tap(find.widgetWithText(NxButton, '로그아웃'));
      await tester.pump();
      expect(auth.signedOut, 1);
    });
  });
}

Space _space(String id) =>
    Space(id: id, slug: id, name: id, role: SpaceRole.member);

class _FakeWorkspace implements WorkspaceRepository {
  _FakeWorkspace({
    required this.online,
    required List<Space> spaces,
    List<Space>? afterRefresh,
  }) : _spaces = spaces,
       _afterRefresh = afterRefresh ?? spaces;

  final bool online;
  List<Space> _spaces;
  final List<Space> _afterRefresh;
  int refreshed = 0;

  @override
  Future<bool> refreshSpaces() async {
    refreshed++;
    if (!online) return false;
    _spaces = _afterRefresh;
    return true;
  }

  @override
  Stream<List<Space>> watchSpaces() => Stream.value(_spaces);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeAuth extends AuthController {
  int signedOut = 0;

  @override
  AuthState build() =>
      const AuthSignedIn(User(id: 'u1', email: 'new@example.com', name: 'New'));

  @override
  Future<void> signOut() async => signedOut++;
}
