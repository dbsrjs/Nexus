import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/repo_browse.dart';
import '../../shared/widgets/back_button.dart';
import '../../ui/ui.dart';
import 'browse_controller.dart';
import 'code_highlight.dart';
import 'repo_controller.dart';
import '../ai/ai_panel.dart';
import '../ai/ai_request.dart';

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
    _source =
        ref.read(browseSourceProvider) ??
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
        // 커밋 상세에서 왔으면 그 sha 가 기준이다. **브랜치 목록에는 없는 값이라**
        // 선택기는 짧은 sha 를 자리 표시로 보인다(아래 _BranchSelect).
        _ref =
            widget.initialRef ??
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
      _openDir(
        parts.length <= 1 ? '' : parts.sublist(0, parts.length - 1).join('/'),
      );
      return;
    }
    _openDir(_path);
  }

  /// 이 저장소를 붙여 AI 패널을 연다(13-2). 이름은 이미 받아 둔 저장소
  /// 목록에서 찾고, 없으면 일반 이름을 쓴다 — 이름 하나 때문에 기다리지 않는다.
  void _openAi() {
    final repos = ref.read(spaceReposProvider(widget.spaceId)).value;
    final name =
        repos
            ?.where((r) => r.id == widget.repoId)
            .map((r) => r.name)
            .firstOrNull ??
        '저장소';
    showAiPanel(
      context,
      spaceId: widget.spaceId,
      contexts: [RepoContext(repoId: widget.repoId, repoName: name)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = '/s/${widget.spaceId}/repos/${widget.repoId}';
    return NxPage(
      header: NxHeader(
        title: '코드',
        leading: NxBackButton(fallback: '/s/${widget.spaceId}/repos'),
        actions: [
          if (_branches.isNotEmpty)
            _BranchSelect(
              branches: _branches,
              current: _ref,
              onChanged: (v) {
                if (v == _ref) return;
                setState(() => _ref = v);
                // **브랜치를 바꾸면 루트로 돌아간다** — 지금 경로가 새
                // 브랜치에도 있으리라는 보장이 없다.
                _openDir('');
              },
            ),
          NxButton(
            label: '커밋',
            kind: NxButtonKind.ghost,
            size: NxSize.sm,
            onPressed: () => context.push(
              '$base/commits?ref=${Uri.encodeQueryComponent(_ref)}',
            ),
          ),
          // PR 은 브랜치에 매이지 않는다 — ref 를 붙이지 않는다.
          NxButton(
            label: 'PR',
            kind: NxButtonKind.ghost,
            size: NxSize.sm,
            onPressed: () => context.push('$base/pulls'),
          ),
          NxIconButton(icon: NxIcons.ai, label: 'AI 에게 묻기', onPressed: _openAi),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const NxDivider(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    final nx = NxTheme.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(NxSpacing.sp7),
        child: NxSkeleton(lines: 8, lineHeight: 16),
      );
    }

    final error = _error;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, style: nx.text.base),
            const SizedBox(height: NxSpacing.sp4),
            NxButton(
              label: '다시 확인',
              kind: NxButtonKind.secondary,
              onPressed: _retry,
            ),
          ],
        ),
      );
    }

    final blob = _blob;
    if (blob != null) return _FileBody(blob: blob);

    final entries = _entries ?? const <TreeEntry>[];
    if (entries.isEmpty) {
      return Center(child: Text('비어 있습니다', style: nx.text.secondary));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: NxSpacing.sp5,
        vertical: NxSpacing.sp4,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        return _EntryRow(
          entry: e,
          onPressed: () => e.isDir ? _openDir(e.path) : _openFile(e.path),
        );
      },
    );
  }
}

/// 트리 한 줄. **폴더는 이름 뒤 `/`** 로 가른다 — 앞 장식 아이콘을 두지 않는다(15단계 D5).
class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.onPressed});

  final TreeEntry entry;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    return NxPressable(
      onPressed: onPressed,
      semanticLabel: entry.isDir ? '${entry.name} 폴더' : entry.name,
      builder: (context, s) => AnimatedContainer(
        duration: NxMotion.micro,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: NxSpacing.inset),
        decoration: BoxDecoration(
          color: s.hovered || s.pressed ? c.bgElevated : NxColors.transparent,
          borderRadius: BorderRadius.circular(NxRadius.md),
        ),
        child: Row(
          children: [
            Flexible(
              child: Text(
                entry.name,
                overflow: TextOverflow.ellipsis,
                style: nx.text.base.copyWith(
                  fontWeight: entry.isDir ? FontWeight.w600 : null,
                ),
              ),
            ),
            if (entry.isDir)
              Text('/', style: nx.text.mono.copyWith(fontSize: NxFontSize.sm)),
          ],
        ),
      ),
    );
  }
}

/// 브랜치 고르기. sha 로 열렸으면 목록에 없는 값이라 **짧은 sha 를 자리 표시로** 보인다.
class _BranchSelect extends StatelessWidget {
  const _BranchSelect({
    required this.branches,
    required this.current,
    required this.onChanged,
  });

  final List<RepoBranch> branches;
  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final known = branches.any((b) => b.name == current);
    return NxSelect<String>(
      width: 180,
      value: known ? current : null,
      placeholder: current.length > 7 ? current.substring(0, 7) : current,
      options: [for (final b in branches) (b.name, b.name)],
      onChanged: onChanged,
    );
  }
}

class _Crumbs extends StatelessWidget {
  const _Crumbs({
    required this.crumbs,
    required this.onRoot,
    required this.onCrumb,
  });

  final List<String> crumbs;
  final VoidCallback onRoot;
  final void Function(int index) onCrumb;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final slash = Text(
      '/',
      style: nx.text.mono.copyWith(fontSize: NxFontSize.sm),
    );
    Widget crumb(String label, VoidCallback onPressed) => NxButton(
      label: label,
      kind: NxButtonKind.ghost,
      size: NxSize.sm,
      onPressed: onPressed,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: NxSpacing.sp5,
        vertical: NxSpacing.sp3,
      ),
      child: Row(
        children: [
          crumb('/', onRoot),
          for (var i = 0; i < crumbs.length; i++) ...[
            if (i > 0) slash,
            crumb(crumbs[i], () => onCrumb(i)),
          ],
        ],
      ),
    );
  }
}

/// **등폭 폰트 + 줄 번호.** 색칠은 언어 규칙 없는 공통 넷(code_highlight.dart).
///
/// **긴 줄은 접지 않고 가로로 스크롤한다** — 접으면 줄 번호와 내용이 어긋나
/// 코드를 읽을 수 없다.
class _FileBody extends StatelessWidget {
  const _FileBody({required this.blob});

  final BlobView blob;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final message = blob.omittedMessage;
    if (message != null) {
      return Center(child: Text(message, style: nx.text.secondary));
    }

    final lines = (blob.content ?? '').split('\n');
    final style = nx.text.code.copyWith(height: 1.5);
    final palette = CodePalette.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(NxSpacing.sp5),
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
                      style: style.copyWith(color: nx.colors.borderStrong),
                    ),
                  ),
                  const SizedBox(width: NxSpacing.sp5),
                  CodeLine(line: lines[i], style: style, palette: palette),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
