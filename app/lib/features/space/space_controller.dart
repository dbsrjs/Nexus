import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/spaces_api.dart';
import '../../domain/models/space.dart';
import '../auth/auth_controller.dart';

final spacesApiProvider =
    Provider<SpacesApi>((ref) => SpacesApi(ref.watch(apiClientProvider)));

/// 내가 속한 스페이스 목록.
///
/// 인증 상태를 지켜본다 — 로그아웃했다가 다른 계정으로 들어오면 이전 계정의
/// 목록이 남아 있으면 안 된다. authControllerProvider 를 watch 하므로
/// 상태가 바뀌면 이 provider 가 자동으로 다시 만들어진다.
final spacesProvider = FutureProvider<List<Space>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthSignedIn) return const [];
  return ref.watch(spacesApiProvider).list();
});

/// 현재 열려 있는 스페이스 id.
///
/// **라우트(`/s/:spaceId`)가 진실의 원천이고** 셸이 그 값을 여기에 실어 준다.
/// Riverpod 3 에서 `StateProvider` 는 legacy 로 밀렸으므로 Notifier 를 쓴다.
class CurrentSpaceId extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final currentSpaceIdProvider =
    NotifierProvider<CurrentSpaceId, String?>(CurrentSpaceId.new);

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
