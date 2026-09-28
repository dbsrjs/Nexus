import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/repo_browse.dart';
import '../../shared/widgets/back_button.dart';
import '../../ui/ui.dart';
import 'browse_controller.dart';

/// 바뀐 파일 목록. **diff 를 그리지 않는다**(설계 §3) — 파일을 누르면 그
/// 시점의 전문이 열린다. PR 상세도 같은 모양을 쓴다.
class ChangedFileList extends StatelessWidget {
  const ChangedFileList({super.key, required this.files, required this.onTap});

  final List<ChangedFile> files;
  final void Function(ChangedFile file) onTap;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    if (files.isEmpty) {
      return Text('바뀐 파일이 없습니다', style: nx.text.secondary);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in files)
          ChangedFileRow(
            path: f.path,
            status: f.statusLabel,
            // 지워진 파일은 그 커밋 시점에 없다 — 열어도 404 다.
            onPressed: f.status == 'removed' ? null : () => onTap(f),
          ),
      ],
    );
  }
}

/// 바뀐 파일 한 줄 — 경로(모노)와 오른쪽 상태 글자. 누를 수 없으면 흐리다.
class ChangedFileRow extends StatelessWidget {
  const ChangedFileRow({
    super.key,
    required this.path,
    required this.status,
    this.trailing,
    this.onPressed,
  });

  final String path;
  final String status;

  /// 상태 앞에 붙는 것(PR 의 +/− 줄 수).
  final Widget? trailing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final enabled = onPressed != null;
    return NxRow(
      title: path,
      dense: true,
      titleStyle: nx.text.code.copyWith(
        fontSize: 12,
        height: 1.3,
        color: enabled ? c.textPrimary : c.borderStrong,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?trailing,
          if (trailing != null) const SizedBox(width: NxSpacing.sp4),
          Text(status, style: nx.text.meta),
        ],
      ),
      onPressed: onPressed,
    );
  }
}

/// 커밋 하나. 메시지와 바뀐 파일 목록을 보여 준다.
class CommitDetailScreen extends ConsumerStatefulWidget {
  const CommitDetailScreen({
    super.key,
    required this.spaceId,
    required this.repoId,
    required this.sha,
  });

  final String spaceId;
  final String repoId;
  final String sha;

  @override
  ConsumerState<CommitDetailScreen> createState() => _CommitDetailScreenState();
}

class _CommitDetailScreenState extends ConsumerState<CommitDetailScreen> {
  CommitDetail? _commit;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(browseApiProvider)
          .commit(widget.spaceId, widget.repoId, widget.sha);
      if (!mounted) return;
      setState(() {
        _commit = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '커밋을 불러오지 못했습니다';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final commit = _commit;

    return NxPage(
      header: NxHeader(
        titleWidget: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            commit?.shortSha ?? '커밋',
            style: nx.text.mono.copyWith(
              fontSize: 14,
              color: nx.colors.textPrimary,
            ),
          ),
        ),
        leading: NxBackButton(
          fallback: '/s/${widget.spaceId}/repos/${widget.repoId}/browse',
        ),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(NxSpacing.sp7),
              child: NxSkeleton(lines: 6),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: nx.text.base),
                  const SizedBox(height: NxSpacing.sp4),
                  NxButton(
                    label: '다시 확인',
                    kind: NxButtonKind.secondary,
                    onPressed: _load,
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(NxSpacing.sp7),
              children: [
                Text(commit!.title, style: nx.text.title),
                if (commit.bodyText.isNotEmpty) ...[
                  const SizedBox(height: NxSpacing.sp4),
                  Text(commit.bodyText, style: nx.text.secondary),
                ],
                const SizedBox(height: NxSpacing.sp4),
                Row(
                  children: [
                    Text(commit.shortSha, style: nx.text.mono),
                    if (commit.authorName != null) ...[
                      const SizedBox(width: NxSpacing.sp4),
                      Text(commit.authorName!, style: nx.text.meta),
                    ],
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: NxSpacing.sp7),
                  child: NxDivider(),
                ),
                Text('바뀐 파일 ${commit.files.length}개', style: nx.text.strong),
                const SizedBox(height: NxSpacing.sp4),
                ChangedFileList(
                  files: commit.files,
                  // **10-3a 의 파일 보기를 그 sha 로 연다** — diff 대신
                  // 그 시점의 전문이다.
                  onTap: (f) => context.push(
                    '/s/${widget.spaceId}/repos/${widget.repoId}/browse'
                    '?ref=${Uri.encodeQueryComponent(widget.sha)}'
                    '&path=${Uri.encodeQueryComponent(f.path)}',
                  ),
                ),
              ],
            ),
    );
  }
}
