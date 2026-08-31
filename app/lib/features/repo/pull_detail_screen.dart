import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../domain/models/pull.dart';
import '../../shared/markdown/markdown_body.dart';
import 'browse_controller.dart';
import 'pulls_screen.dart';

typedef PullKey = ({String spaceId, String repoId, int number});
typedef PullView = ({PullDetail pull, List<PullChangedFile> files, bool truncated});

/// 상세와 바뀐 파일을 **한 provider 가 함께** 받는다 — 화면은 스피너 하나만
/// 그리면 되고, 위젯 테스트가 override 할 자리도 하나다.
final pullDetailProvider = FutureProvider.family<PullView, PullKey>((ref, key) async {
  final api = ref.read(pullsApiProvider);
  final pull = await api.detail(key.spaceId, key.repoId, key.number);
  final files = await api.files(key.spaceId, key.repoId, key.number);
  return (pull: pull, files: files.files, truncated: files.truncated);
});

/// 리뷰 상태 칩. `review` 가 `null` 이면 이 위젯 자체가 쓰이지 않는다 — 리뷰
/// 칸을 만들지 않는 판단은 부르는 쪽(`_PullDetailBody`)이 한다.
class _ReviewChip extends StatelessWidget {
  const _ReviewChip({required this.review});

  final PullReviewState review;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (review) {
      PullReviewState.approved => ('승인됨', NexusColors.success),
      PullReviewState.changesRequested => ('변경 요청됨', NexusColors.danger),
    };
    return Chip(
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    );
  }
}

/// 바뀐 파일 목록. **`removed` 는 누를 수 없다**(회색) — head 시점에 없어
/// 열어도 404 다. `renamed` 는 `old → new` 로 그린다.
///
/// 파일 행은 반드시 `ListTile` 이어야 한다 — 위젯 테스트가 `onTap == null`
/// 로 "누를 수 없음"을 확인한다.
class PullFileList extends StatelessWidget {
  const PullFileList({super.key, required this.files, required this.onTap});

  final List<PullChangedFile> files;
  final void Function(PullChangedFile file) onTap;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const Text('바뀐 파일이 없습니다');

    return Column(
      children: [
        for (final f in files)
          ListTile(
            dense: true,
            leading: Icon(Icons.circle, size: 10, color: _statusColor(f.status)),
            title: Text(
              f.status == 'renamed' && f.previousPath != null
                  ? '${f.previousPath} → ${f.path}'
                  : f.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              '+${f.additions} −${f.deletions}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: f.status == 'removed' ? null : () => onTap(f),
            enabled: f.status != 'removed',
          ),
      ],
    );
  }

  Color _statusColor(String status) => switch (status) {
        'added' => NexusColors.success,
        'removed' => NexusColors.danger,
        'renamed' => NexusColors.merged,
        _ => NexusColors.warning,
      };
}

/// PR 하나. 본문 · 변경량 · 리뷰 · 바뀐 파일을 보여 준다.
class PullDetailScreen extends ConsumerWidget {
  const PullDetailScreen({
    super.key,
    required this.spaceId,
    required this.repoId,
    required this.number,
  });

  final String spaceId;
  final String repoId;
  final int number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (spaceId: spaceId, repoId: repoId, number: number);
    final async = ref.watch(pullDetailProvider(key));
    final htmlUrl = switch (async) {
      AsyncData(:final value) => value.pull.htmlUrl,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('#$number'),
        actions: [
          if (htmlUrl != null)
            IconButton(
              tooltip: 'GitHub 에서 열기',
              icon: const Icon(Icons.open_in_new),
              onPressed: () =>
                  launchUrl(Uri.parse(htmlUrl), mode: LaunchMode.externalApplication),
            ),
        ],
      ),
      body: switch (async) {
        AsyncError() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('PR 을 불러오지 못했습니다'),
                const SizedBox(height: NexusSpacing.sp4),
                OutlinedButton(
                  onPressed: () => ref.invalidate(pullDetailProvider(key)),
                  child: const Text('다시 확인'),
                ),
              ],
            ),
          ),
        AsyncData(:final value) =>
          _PullDetailBody(spaceId: spaceId, repoId: repoId, view: value),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _PullDetailBody extends StatelessWidget {
  const _PullDetailBody({
    required this.spaceId,
    required this.repoId,
    required this.view,
  });

  final String spaceId;
  final String repoId;
  final PullView view;

  @override
  Widget build(BuildContext context) {
    final pull = view.pull;
    final subtitleParts = <String>[
      if (pull.authorLogin != null) '@${pull.authorLogin}',
      '${pull.sourceBranch ?? '?'} → ${pull.targetBranch ?? '?'}',
    ];

    return ListView(
      padding: const EdgeInsets.all(NexusSpacing.sp6),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(pull.title, style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(width: NexusSpacing.sp4),
            PullStateChip(state: pull.state, draft: pull.draft),
          ],
        ),
        const SizedBox(height: NexusSpacing.sp2),
        Text(
          '#${pull.number} · ${subtitleParts.join(' · ')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        // **모르면 말하지 않는다** — 0 으로 그리면 "안 바뀐 PR" 로 읽힌다.
        if (pull.additions != null) ...[
          const SizedBox(height: NexusSpacing.sp4),
          Text(
            '+${pull.additions} −${pull.deletions} · 파일 ${pull.changedFiles}개',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if ((pull.body ?? '').isNotEmpty) ...[
          const SizedBox(height: NexusSpacing.sp6),
          MarkdownBody(body: pull.body!),
        ],
        // **`review` 가 `null` 이면 리뷰 칸 자체를 만들지 않는다** — 혼자
        // 쓰는 저장소에서는 늘 비는 값이라, 빈 칸은 잡음이다.
        if (pull.review != null) ...[
          const Divider(height: NexusSpacing.sp9),
          Row(
            children: [
              Text('리뷰', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(width: NexusSpacing.sp4),
              _ReviewChip(review: pull.review!),
            ],
          ),
        ],
        const Divider(height: NexusSpacing.sp9),
        Text(
          '바뀐 파일 ${view.files.length}개',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: NexusSpacing.sp4),
        PullFileList(
          files: view.files,
          // **diff 를 그리지 않는다** — 10-3a 의 파일 보기를 head 브랜치로
          // 연다(10-3b 의 커밋 상세와 같은 판단).
          onTap: (f) => context.push(
            '/s/$spaceId/repos/$repoId/browse'
            '?ref=${Uri.encodeQueryComponent(pull.sourceBranch ?? '')}'
            '&path=${Uri.encodeQueryComponent(f.path)}',
          ),
        ),
        // **`truncated` 면 조용히 자르지 않는다.**
        if (view.truncated) ...[
          const SizedBox(height: NexusSpacing.sp4),
          const Text('파일이 많아 300개까지만 보여 줍니다.'),
          if (pull.htmlUrl != null)
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(pull.htmlUrl!),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('GitHub 에서 보기'),
            ),
        ],
      ],
    );
  }
}
