import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/connections_api.dart';
import '../../domain/models/connection.dart';
import '../auth/auth_controller.dart';

// apiClientProvider 는 features/auth/auth_controller.dart:32 에 있다.
// 다른 API provider(channelsApiProvider 등)도 전부 여기서 가져다 쓴다.
final connectionsApiProvider = Provider<ConnectionsApi>(
  (ref) => ConnectionsApi(ref.watch(apiClientProvider)),
);

/// 연결 상태. **캐시하지 않는다** — 오프라인에서 볼 이유가 약하고, 캐시하면
/// GitHub 쪽 변화와 어긋난 채로 굳는다 (설계 §9).
final connectionsProvider = FutureProvider<List<GithubConnection>>(
  (ref) => ref.watch(connectionsApiProvider).list(),
);

/// 없으면 `null`. 화면은 이 하나로 분기한다.
final githubConnectionProvider = Provider<GithubConnection?>((ref) {
  final list = ref.watch(connectionsProvider).value;
  if (list == null || list.isEmpty) return null;

  return list.firstWhere(
    (c) => c.provider == 'github',
    orElse: () => list.first,
  );
});
