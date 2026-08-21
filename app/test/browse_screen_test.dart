import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/repo_browse.dart';
import 'package:nexus_app/features/repo/browse_controller.dart';
import 'package:nexus_app/features/repo/browse_screen.dart';

/// Riverpod 3 은 `Override` 를 export 하지 않아 적재 함수를 받는다
/// (10-2 의 repos_screen_test 와 같은 방식).
Widget harness({
  required Future<({List<RepoBranch> branches, String? defaultBranch})> Function()
      branches,
  required Future<({String ref, List<TreeEntry> entries})> Function(String path) tree,
  required Future<BlobView> Function(String path) blob,
}) {
  return ProviderScope(
    overrides: [
      browseSourceProvider.overrideWith(
        (ref) => _FakeSource(branches: branches, tree: tree, blob: blob),
      ),
    ],
    child: const MaterialApp(
      home: BrowseScreen(spaceId: 'space-1', repoId: 'repo-1'),
    ),
  );
}

class _FakeSource implements BrowseSource {
  _FakeSource({required this.branches, required this.tree, required this.blob});

  @override
  final Future<({List<RepoBranch> branches, String? defaultBranch})> Function()
      branches;
  @override
  final Future<({String ref, List<TreeEntry> entries})> Function(String path) tree;
  @override
  final Future<BlobView> Function(String path) blob;
}

Future<({List<RepoBranch> branches, String? defaultBranch})> _mainOnly() async =>
    (branches: const [RepoBranch(name: 'main')], defaultBranch: 'main');

final _rootTree = (
  ref: 'main',
  entries: const [
    TreeEntry(name: 'src', path: 'src', type: 'dir', size: null),
    TreeEntry(name: 'README.md', path: 'README.md', type: 'file', size: 12),
  ],
);

void main() {
  testWidgets('루트 목록을 그린다', (tester) async {
    await tester.pumpWidget(harness(
      branches: _mainOnly,
      tree: (_) async => _rootTree,
      blob: (_) async => const BlobView(path: '', size: 0),
    ));
    await tester.pumpAndSettle();

    expect(find.text('src'), findsOneWidget);
    expect(find.text('README.md'), findsOneWidget);
  });

  testWidgets('파일을 누르면 본문이 보인다', (tester) async {
    await tester.pumpWidget(harness(
      branches: _mainOnly,
      tree: (_) async => _rootTree,
      blob: (path) async =>
          BlobView(path: path, size: 12, content: 'hello world\n', omitted: null),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('README.md'));
    await tester.pumpAndSettle();

    expect(find.textContaining('hello world'), findsOneWidget);
  });

  testWidgets('본문이 없으면 이유를 말한다', (tester) async {
    await tester.pumpWidget(harness(
      branches: _mainOnly,
      tree: (_) async => _rootTree,
      blob: (path) async =>
          BlobView(path: path, size: 4, content: null, omitted: 'binary'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('README.md'));
    await tester.pumpAndSettle();

    // 조용히 빈 화면을 그리면 "빈 파일"과 구분되지 않는다.
    expect(find.text('미리 볼 수 없는 파일입니다'), findsOneWidget);
  });

  testWidgets('폴더를 누르면 그 안으로 들어간다', (tester) async {
    await tester.pumpWidget(harness(
      branches: _mainOnly,
      tree: (path) async => path == 'src'
          ? (
              ref: 'main',
              entries: const [
                TreeEntry(name: 'main.ts', path: 'src/main.ts', type: 'file', size: 3),
              ],
            )
          : _rootTree,
      blob: (_) async => const BlobView(path: '', size: 0),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('src'));
    await tester.pumpAndSettle();

    expect(find.text('main.ts'), findsOneWidget);
    // 빵부스러기로 되돌아갈 길이 있어야 한다 — 라우트를 쌓지 않기 때문이다.
    expect(find.text('/'), findsWidgets);
  });
}
