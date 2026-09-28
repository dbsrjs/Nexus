import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/repo_browse.dart';
import '../../shared/widgets/back_button.dart';
import '../../ui/ui.dart';
import 'browse_controller.dart';

/// 커밋 목록. **두 곳이 같은 위젯을 쓴다** — 그 push 에 들어온 커밋들과
/// 브랜치 이력이다. 다르게 보이면 사용자가 두 목록을 다른 것으로 읽는다
/// (설계 §2).
class CommitList extends StatelessWidget {
  const CommitList({
    super.key,
    required this.commits,
    required this.onTap,
    this.onMore,
  });

  final List<CommitSummary> commits;
  final void Function(CommitSummary commit) onTap;

  /// 다음 장이 있으면 목록 끝에 "더 불러오기"를 그린다.
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    if (commits.isEmpty) {
      return Center(child: Text('커밋이 없습니다', style: nx.text.secondary));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: NxSpacing.sp5,
        vertical: NxSpacing.sp4,
      ),
      itemCount: commits.length + (onMore == null ? 0 : 1),
      itemBuilder: (_, i) {
        if (i == commits.length) {
          return Padding(
            padding: const EdgeInsets.only(top: NxSpacing.sp4),
            child: NxButton(
              label: '더 불러오기',
              kind: NxButtonKind.ghost,
              onPressed: onMore,
            ),
          );
        }
        return _CommitRow(commit: commits[i], onPressed: () => onTap(commits[i]));
      },
    );
  }
}

class _CommitRow extends StatelessWidget {
  const _CommitRow({required this.commit, required this.onPressed});

  final CommitSummary commit;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final count = commit.changedCount;
    final who = commit.authorName;
    final meta = [
      ?who,
      // **모르면 말하지 않는다** — 0 으로 그리면 "안 바뀐 커밋"이 된다.
      if (count != null) '파일 $count개',
    ];

    return NxPressable(
      onPressed: onPressed,
      builder: (context, s) => AnimatedContainer(
        duration: NxMotion.micro,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: s.hovered || s.pressed
              ? c.bgElevated
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(NxRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목만 그린다. 본문까지 넣으면 목록이 문단이 된다.
            Text(
              commit.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: nx.text.base,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(commit.shortSha, style: nx.text.mono),
                if (meta.isNotEmpty) ...[
                  const SizedBox(width: NxSpacing.sp4),
                  Flexible(
                    child: Text(
                      meta.join(' · '),
                      overflow: TextOverflow.ellipsis,
                      style: nx.text.meta,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 커밋 목록 화면. `eventId` 를 받으면 그 push 의 커밋을, `ref` 를 받으면
/// 브랜치 이력을 그린다.
class CommitsScreen extends ConsumerStatefulWidget {
  const CommitsScreen({
    super.key,
    required this.spaceId,
    this.eventId,
    this.repoId,
    this.branchRef,
  });

  final String spaceId;

  /// 채널 메시지에서 들어온 경우.
  final String? eventId;

  /// 탐색 화면의 '커밋' 탭에서 들어온 경우.
  final String? repoId;
  final String? branchRef;

  @override
  ConsumerState<CommitsScreen> createState() => _CommitsScreenState();
}

class _CommitsScreenState extends ConsumerState<CommitsScreen> {
  final _commits = <CommitSummary>[];
  String? _repoId;
  String? _title;
  String? _nextCursor;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repoId = widget.repoId;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(browseApiProvider);

      if (widget.eventId != null) {
        final view = await api.event(widget.spaceId, widget.eventId!);
        if (!mounted) return;
        setState(() {
          _repoId = view.repoId;
          _title = view.ref == null
              ? view.repoFullPath
              : '${view.repoFullPath} · ${view.ref}';
          _commits
            ..clear()
            ..addAll(view.commits);
          _loading = false;
        });
        return;
      }

      final res = await api.commits(
        widget.spaceId,
        widget.repoId!,
        ref: widget.branchRef ?? '',
        cursor: _nextCursor ?? '',
      );
      if (!mounted) return;
      setState(() {
        _title = widget.branchRef;
        _commits.addAll(res.commits);
        _nextCursor = res.nextCursor;
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
    final repoId = _repoId;
    return NxPage(
      header: NxHeader(
        title: '커밋',
        // 브랜치 이력이면 브랜치, push 에서 왔으면 저장소 · ref 를 제목 곁에.
        subtitle: _title,
        leading: NxBackButton(
          fallback: repoId == null
              ? '/s/${widget.spaceId}'
              : '/s/${widget.spaceId}/repos/$repoId/browse',
        ),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    final nx = NxTheme.of(context);
    if (_loading && _commits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(NxSpacing.sp7),
        child: NxSkeleton(lines: 6, lineHeight: 32),
      );
    }

    final error = _error;
    if (error != null && _commits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, style: nx.text.base),
            const SizedBox(height: NxSpacing.sp4),
            NxButton(
              label: '다시 확인',
              kind: NxButtonKind.secondary,
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    return CommitList(
      commits: _commits,
      onMore: _nextCursor == null || _loading ? null : _load,
      onTap: (c) {
        final repoId = _repoId;
        if (repoId == null) return;
        context.push('/s/${widget.spaceId}/repos/$repoId/commits/${c.sha}');
      },
    );
  }
}
