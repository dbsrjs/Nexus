import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/repo_browse.dart';
import 'browse_controller.dart';

/// 바뀐 파일 목록. **diff 를 그리지 않는다**(설계 §3) — 파일을 누르면 그
/// 시점의 전문이 열린다.
class ChangedFileList extends StatelessWidget {
  const ChangedFileList({super.key, required this.files, required this.onTap});

  final List<ChangedFile> files;
  final void Function(ChangedFile file) onTap;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const Text('바뀐 파일이 없습니다');

    return Column(
      children: [
        for (final f in files)
          ListTile(
            dense: true,
            title: Text(f.path, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(
              f.statusLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // 지워진 파일은 그 커밋 시점에 없다 — 열어도 404 다.
            onTap: f.status == 'removed' ? null : () => onTap(f),
            enabled: f.status != 'removed',
          ),
      ],
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
    final commit = _commit;

    return Scaffold(
      appBar: AppBar(
        title: Text(commit?.shortSha ?? '커밋'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _load,
                        child: const Text('다시 확인'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      commit!.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (commit.bodyText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        commit.bodyText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      [
                        commit.shortSha,
                        if (commit.authorName != null) commit.authorName!,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(height: 32),
                    Text(
                      '바뀐 파일 ${commit.files.length}개',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
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
