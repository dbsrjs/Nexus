import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/browse_api.dart';
import '../../domain/models/repo_browse.dart';
import '../auth/auth_controller.dart';

/// 화면이 보는 창구. **`BrowseApi` 를 직접 잡지 않는다** — 이 화면은 브랜치 →
/// 트리 → 파일을 순서대로 부르므로, 위젯 테스트가 provider 셋을 각각 덮는
/// 것보다 창구 하나를 덮는 편이 읽힌다.
abstract class BrowseSource {
  Future<({List<RepoBranch> branches, String? defaultBranch})> Function() get branches;
  Future<({String ref, List<TreeEntry> entries})> Function(String path) get tree;
  Future<BlobView> Function(String path) get blob;
}

/// 테스트가 덮어쓰는 자리. 비어 있으면 화면이 `ApiBrowseSource` 를 만든다.
final browseSourceProvider = Provider<BrowseSource?>((ref) => null);

final browseApiProvider = Provider<BrowseApi>(
  (ref) => BrowseApi(ref.watch(apiClientProvider)),
);

/// 실제 구현. **`ref` 를 함수로 받는다** — 브랜치를 바꾸면 그 뒤의 호출이
/// 새 값을 써야 하는데, 값으로 받으면 만들 때 고정된다.
class ApiBrowseSource implements BrowseSource {
  ApiBrowseSource({
    required BrowseApi api,
    required String spaceId,
    required String repoId,
    required String Function() currentRef,
  })  : _api = api,
        _spaceId = spaceId,
        _repoId = repoId,
        _currentRef = currentRef;

  final BrowseApi _api;
  final String _spaceId;
  final String _repoId;
  final String Function() _currentRef;

  @override
  Future<({List<RepoBranch> branches, String? defaultBranch})> Function() get branches =>
      () => _api.branches(_spaceId, _repoId);

  @override
  Future<({String ref, List<TreeEntry> entries})> Function(String path) get tree =>
      (path) => _api.tree(_spaceId, _repoId, ref: _currentRef(), path: path);

  @override
  Future<BlobView> Function(String path) get blob =>
      (path) => _api.blob(_spaceId, _repoId, ref: _currentRef(), path: path);
}
