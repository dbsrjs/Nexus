import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/repos_api.dart';
import '../../domain/models/repo.dart';
import '../auth/auth_controller.dart';

final reposApiProvider = Provider<ReposApi>(
  (ref) => ReposApi(ref.watch(apiClientProvider)),
);

/// 이 스페이스에 붙은 저장소. **캐시하지 않는다**(설계 §9) — drift 를
/// 건드리지 않으므로 `schemaVersion` 도 그대로다.
final spaceReposProvider =
    FutureProvider.family<List<SpaceRepo>, String>((ref, spaceId) {
  return ref.watch(reposApiProvider).spaceRepos(spaceId);
});
