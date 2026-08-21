import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/repo_browse.dart';
import 'browse_controller.dart';

/// 저장소 안을 들여다본다. **캐시하지 않는다**(설계 §4).
///
/// **폴더를 열 때 라우트를 쌓지 않는다** — 다섯 단계 들어간 뒤 저장소로
/// 나오는 데 다섯 번을 눌러야 하기 때문이다. 경로는 이 화면의 상태이고,
/// 되돌아가는 길은 빵부스러기가 맡는다.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({
    super.key,
    required this.spaceId,
    required this.repoId,
    this.initialRef,
    this.initialPath,
  });

  final String spaceId;
  final String repoId;

  /// 커밋 상세에서 들어오면 그 sha 로 시작한다 — 그 시점의 전문을 본다(10-3b).
  final String? initialRef;

  /// 함께 오면 그 파일을 곧바로 연다.
  final String? initialPath;

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  late final BrowseSource _source;

  var _ref = '';
  var _path = '';
  List<RepoBranch> _branches = const [];
  List<TreeEntry>? _entries;
  BlobView? _blob;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _source = ref.read(browseSourceProvider) ??
        ApiBrowseSource(
          api: ref.read(browseApiProvider),
          spaceId: widget.spaceId,
          repoId: widget.repoId,
          currentRef: () => _ref,
        );
    _start();
  }

  Future<void> _start() async {
    try {
      final res = await _source.branches();
      if (!mounted) return;
      setState(() {
        _branches = res.branches;
        // 커밋 상세에서 왔으면 그 sha 가 기준이다. **드롭다운에는 없는 값이라**
        // 브랜치 선택기는 비워 둔다(아래 value 계산이 그것을 처리한다).
        _ref = widget.initialRef ??
            res.defaultBranch ??
            (res.branches.isEmpty ? '' : res.branches.first.name);
      });

      final path = widget.initialPath;
      if (path != null && path.isNotEmpty) {
        await _openFile(path);
        return;
      }
      await _openDir('');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '저장소를 열지 못했습니다';
      });
    }
  }

  Future<void> _openDir(String path) async {
    setState(() {
      _loading = true;
      _error = null;
      _blob = null;
    });
    try {
      final res = await _source.tree(path);
      if (!mounted) return;
      setState(() {
        _path = path;
        _ref = res.ref;
        _entries = res.entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '목록을 불러오지 못했습니다';
      });
    }
  }

  Future<void> _openFile(String path) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _source.blob(path);
      if (!mounted) return;
      setState(() {
        _path = path;
        _blob = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '파일을 불러오지 못했습니다';
      });
    }
  }

  List<String> get _crumbs => _path.isEmpty ? const [] : _path.split('/');

  /// 파일을 보고 있으면 그 파일이 든 폴더로, 폴더면 그 위로.
  void _retry() {
    if (_blob != null) {
      final parts = _crumbs;
      _openDir(parts.length <= 1 ? '' : parts.sublist(0, parts.length - 1).join('/'));
      return;
    }
    _openDir(_path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('코드'),
        actions: [
          IconButton(
            tooltip: '커밋',
            icon: const Icon(Icons.history, size: 20),
            onPressed: () => context.push(
              '/s/${widget.spaceId}/repos/${widget.repoId}/commits'
              '?ref=${Uri.encodeQueryComponent(_ref)}',
            ),
          ),
          if (_branches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DropdownButton<String>(
                // sha 로 열렸으면 드롭다운에 없는 값이라 비워 둔다 —
                // 없는 값을 주면 DropdownButton 이 던진다.
                value: _branches.any((b) => b.name == _ref) ? _ref : null,
                underline: const SizedBox.shrink(),
                items: [
                  for (final b in _branches)
                    DropdownMenuItem(value: b.name, child: Text(b.name)),
                ],
                onChanged: (v) {
                  if (v == null || v == _ref) return;
                  setState(() => _ref = v);
                  // **브랜치를 바꾸면 루트로 돌아간다** — 지금 경로가 새
                  // 브랜치에도 있으리라는 보장이 없다.
                  _openDir('');
                },
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Crumbs(
            crumbs: _crumbs,
            onRoot: () => _openDir(''),
            onCrumb: (i) {
              final target = _crumbs.take(i + 1).join('/');
              // 마지막 조각이 파일이면 그 자리는 열 것이 없다.
              if (_blob != null && i == _crumbs.length - 1) return;
              _openDir(target);
            },
          ),
          const Divider(height: 1),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final error = _error;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _retry, child: const Text('다시 확인')),
          ],
        ),
      );
    }

    final blob = _blob;
    if (blob != null) return _FileBody(blob: blob);

    final entries = _entries ?? const <TreeEntry>[];
    if (entries.isEmpty) return const Center(child: Text('비어 있습니다'));

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        return ListTile(
          dense: true,
          leading: Icon(
            e.isDir ? Icons.folder_outlined : Icons.description_outlined,
            size: 18,
          ),
          title: Text(e.name),
          onTap: () => e.isDir ? _openDir(e.path) : _openFile(e.path),
        );
      },
    );
  }
}

class _Crumbs extends StatelessWidget {
  const _Crumbs({required this.crumbs, required this.onRoot, required this.onCrumb});

  final List<String> crumbs;
  final VoidCallback onRoot;
  final void Function(int index) onCrumb;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          TextButton(onPressed: onRoot, child: const Text('/')),
          for (var i = 0; i < crumbs.length; i++) ...[
            const Text('/'),
            TextButton(onPressed: () => onCrumb(i), child: Text(crumbs[i])),
          ],
        ],
      ),
    );
  }
}

/// **등폭 폰트 + 줄 번호.** 신택스 하이라이팅은 넣지 않는다 (설계 §4) —
/// 9-3 에서 차트 라이브러리 대신 `CustomPainter` 를 쓴 것과 같은 판단이다.
///
/// **긴 줄은 접지 않고 가로로 스크롤한다** — 접으면 줄 번호와 내용이 어긋나
/// 코드를 읽을 수 없다.
class _FileBody extends StatelessWidget {
  const _FileBody({required this.blob});

  final BlobView blob;

  @override
  Widget build(BuildContext context) {
    final message = blob.omittedMessage;
    if (message != null) return Center(child: Text(message));

    final lines = (blob.content ?? '').split('\n');
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          height: 1.5,
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < lines.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${i + 1}',
                      textAlign: TextAlign.right,
                      style: style?.copyWith(color: Theme.of(context).hintColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(lines[i], style: style),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
