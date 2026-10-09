import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/spaces_api.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/workspace_repository.dart';
import '../../domain/models/space.dart';
import '../auth/auth_controller.dart';
import '../channel/channel_controller.dart';
import '../../core/settable.dart';

/// 로컬 DB. 앱 전체에 하나뿐이다.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return WorkspaceRepository(
    spacesApi: ref.watch(spacesApiProvider),
    // 채널 API 는 channelsApiProvider 하나를 쓴다 — 여기서 따로 만들면 테스트가 그 provider 를
    // 덮어도 저장소에는 닿지 않는다.
    channelsApi: ref.watch(channelsApiProvider),
    db: ref.watch(appDatabaseProvider),
  );
});

final spacesApiProvider = Provider<SpacesApi>(
  (ref) => SpacesApi(ref.watch(apiClientProvider)),
);

/// 내가 속한 스페이스 목록.
///
/// **캐시(drift)를 구독하고 서버는 뒤에서 갱신한다.** 오프라인으로 켜도 목록이
/// 보이고, 그래야 캐시된 대화까지 도달할 수 있다 (docs/앱-설계.md §6).
///
/// 인증 상태를 지켜본다 — 로그아웃했다가 다른 계정으로 들어오면 이전 계정의
/// 목록이 남아 있으면 안 된다.
///
/// **계정 id 만 지켜본다.** 인증 상태 전체를 보면 이름 · 사진을 바꿀 때마다(14단계
/// `replaceUser`) 목록을 다시 받고 의존 provider 를 무효화했다 — 설정 창의 알림 섹션이
/// build 중에 이것을 읽는 순간 그 무효화가 겹쳐 「build 중 setState」 로 멈췄다(15-3).
final spacesProvider = StreamProvider<List<Space>>((ref) {
  final userId = ref.watch(
    authControllerProvider.select((a) => a is AuthSignedIn ? a.user.id : null),
  );
  if (userId == null) return Stream.value(const []);

  final repository = ref.watch(workspaceRepositoryProvider);
  // 캐시를 먼저 흘려보내고, 갱신은 뒤에서 한다. 기다리면 캐시가 있어도 늦어진다.
  Future.microtask(repository.refreshSpaces);
  return repository.watchSpaces();
});

/// 현재 열려 있는 스페이스 id.
///
/// **라우트(`/s/:spaceId`)가 진실의 원천이고** 셸이 그 값을 여기에 실어 준다.
/// Riverpod 3 에서 `StateProvider` 는 legacy 로 밀렸으므로 Notifier 를 쓴다.
final currentSpaceIdProvider =
    NotifierProvider<SettableNotifier<String?>, String?>(
      () => SettableNotifier(null),
    );

/// **서버가 확인한** 내 스페이스 목록에 [spaceId] 가 없는가 — 멤버가 아닌 스페이스 주소로
/// 들어왔다(낡은 링크 · 내보내진 뒤의 새로고침 · 다른 계정으로 바꾼 뒤).
///
/// 캐시 · provider 의 목록으로 판정하지 않는다 — 구독자가 없어 멈춰 있던 provider 는 깨어난 첫
/// 값이 옛 목록이라, 방금 만들거나 참여한 스페이스에서 쫓겨난다(CLAUDE.md §2 «목록에 없다고 곧바로
/// 화면을 옮기지 않는다»). 그래서 서버에 한 번 묻고 **그 답으로만** 정한다. 서버에 못 닿으면
/// 모르는 것이라 false — 오프라인으로 켠 셸은 캐시를 그대로 보인다.
Future<bool> isConfirmedOutsider(
  WorkspaceRepository repository,
  String spaceId,
) async {
  if (!await repository.refreshSpaces()) return false;
  final spaces = await repository.watchSpaces().first;
  return !spaces.any((s) => s.id == spaceId);
}

/// 현재 스페이스의 상세. 목록에서 찾는다 — 별도 요청을 하지 않는다.
final currentSpaceProvider = Provider<Space?>((ref) {
  final id = ref.watch(currentSpaceIdProvider);
  if (id == null) return null;

  final spaces = ref.watch(spacesProvider).value;
  if (spaces == null) return null;

  for (final space in spaces) {
    if (space.id == id) return space;
  }
  return null;
});
