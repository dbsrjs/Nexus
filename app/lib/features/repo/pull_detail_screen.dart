import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/pull.dart';
import '../../shared/markdown/markdown_body.dart';
import '../../shared/widgets/back_button.dart';
import '../../ui/ui.dart';
import 'browse_controller.dart';
import 'pulls_screen.dart';

typedef PullKey = ({String spaceId, String repoId, int number});
typedef PullView = ({
  PullDetail pull,
  List<PullChangedFile> files,
  bool truncated,
});

/// 상세와 바뀐 파일을 **한 provider 가 함께** 받는다 — 화면은 로딩 하나만
/// 그리면 되고, 위젯 테스트가 override 할 자리도 하나다.
///
/// **`autoDispose` 다**(목록과 같은 이유). 빼 두었더니 상세가 앱을 끌 때까지
/// 굳어, 머지된 PR 을 다시 열어도 옛 상태가 보였다.
final pullDetailProvider = FutureProvider.autoDispose
    .family<PullView, PullKey>((ref, key) async {
      final api = ref.read(pullsApiProvider);
      final pull = await api.detail(key.spaceId, key.repoId, key.number);
      final files = await api.files(key.spaceId, key.repoId, key.number);
      return (pull: pull, files: files.files, truncated: files.truncated);
    });

/// 리뷰 상태 표지. `review` 가 `null` 이면 이 위젯 자체가 쓰이지 않는다 — 리뷰
/// 칸을 만들지 않는 판단은 부르는 쪽(`_PullDetailBody`)이 한다.
class _ReviewChip extends StatelessWidget {
  const _ReviewChip({required this.review});

  final PullReviewState review;

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    final (label, color) = switch (review) {
      PullReviewState.approved => ('승인됨', c.success),
      PullReviewState.changesRequested => ('변경 요청됨', c.danger),
    };
    return NxTag(label, dot: true, color: color);
  }
}

/// 바뀐 파일 목록. **`removed` 는 누를 수 없다**(흐림) — head 시점에 없어
/// 열어도 404 다. `renamed` 는 `old → new` 로 그린다.
///
/// 파일 행은 [NxRow] 다 — 위젯 테스트가 `onPressed == null` 로 "누를 수 없음"을
/// 확인한다. 앞의 색 점은 바뀐 종류(추가 · 삭제 · 이름 변경 · 수정)라 뜻이 있다.
class PullFileList extends StatelessWidget {
  const PullFileList({super.key, required this.files, required this.onTap});

  final List<PullChangedFile> files;
  final void Function(PullChangedFile file) onTap;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    if (files.isEmpty) return Text('바뀐 파일이 없습니다', style: nx.text.secondary);

    Color statusColor(String status) => switch (status) {
      'added' => c.success,
      'removed' => c.danger,
      'renamed' => c.merged,
      _ => c.warning,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in files)
          NxRow(
            dense: true,
            leading: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: statusColor(f.status),
                shape: BoxShape.circle,
              ),
            ),
            title: f.status == 'renamed' && f.previousPath != null
                ? '${f.previousPath} → ${f.path}'
                : f.path,
            titleStyle: nx.text.code.copyWith(
              fontSize: 12,
              height: 1.3,
              color: f.status == 'removed' ? c.borderStrong : c.textPrimary,
            ),
            trailing: Text(
              '+${f.additions} −${f.deletions}',
              style: nx.text.mono,
            ),
            onPressed: f.status == 'removed' ? null : () => onTap(f),
          ),
      ],
    );
  }
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
    final nx = NxTheme.of(context);
    final key = (spaceId: spaceId, repoId: repoId, number: number);
    final async = ref.watch(pullDetailProvider(key));
    final htmlUrl = switch (async) {
      AsyncData(:final value) => value.pull.htmlUrl,
      _ => null,
    };

    return NxPage(
      header: NxHeader(
        titleWidget: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '#$number',
            style: nx.text.mono.copyWith(
              fontSize: 14,
              color: nx.colors.textPrimary,
            ),
          ),
        ),
        leading: NxBackButton(fallback: '/s/$spaceId/repos/$repoId/pulls'),
        actions: [
          if (htmlUrl != null)
            NxIconButton(
              icon: NxIcons.external,
              label: 'GitHub 에서 열기',
              onPressed: () => launchUrl(
                Uri.parse(htmlUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
        ],
      ),
      body: switch (async) {
        _ when async.hasError => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PR 을 불러오지 못했습니다', style: nx.text.base),
              const SizedBox(height: NxSpacing.sp4),
              NxButton(
                label: '다시 확인',
                kind: NxButtonKind.secondary,
                onPressed: () => ref.invalidate(pullDetailProvider(key)),
              ),
            ],
          ),
        ),
        AsyncData(:final value) => _PullDetailBody(
          spaceId: spaceId,
          repoId: repoId,
          view: value,
        ),
        _ => const Padding(
          padding: EdgeInsets.all(NxSpacing.sp7),
          child: NxSkeleton(lines: 6),
        ),
      },
    );
  }
}

/// 변경량 한 줄. **아는 것만 이어 붙인다** — 셋 다 모르면 `null` 이라 화면이
/// 그 줄 자체를 만들지 않는다.
String? changeSummary(PullDetail pull) {
  final parts = <String>[
    if (pull.additions != null && pull.deletions != null)
      '+${pull.additions} −${pull.deletions}'
    else if (pull.additions != null)
      '+${pull.additions}'
    else if (pull.deletions != null)
      '−${pull.deletions}',
    if (pull.changedFiles != null) '파일 ${pull.changedFiles}개',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
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
    final nx = NxTheme.of(context);
    final pull = view.pull;
    final subtitleParts = <String>[
      if (pull.authorLogin != null) '@${pull.authorLogin}',
      '${pull.sourceBranch ?? '?'} → ${pull.targetBranch ?? '?'}',
    ];
    const gap = Padding(
      padding: EdgeInsets.symmetric(vertical: NxSpacing.sp7),
      child: NxDivider(),
    );

    return ListView(
      padding: const EdgeInsets.all(NxSpacing.sp7),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(pull.title, style: nx.text.title)),
            const SizedBox(width: NxSpacing.sp4),
            PullStateChip(state: pull.state, draft: pull.draft),
          ],
        ),
        const SizedBox(height: NxSpacing.sp3),
        Text(
          '#${pull.number} · ${subtitleParts.join(' · ')}',
          style: nx.text.mono,
        ),
        // **모르면 말하지 않는다** — 0 으로 그리면 "안 바뀐 PR" 로 읽힌다.
        // 셋이 각각 nullable 이라 **하나만 보고 셋을 그리면 안 된다** —
        // `additions` 만 검사했더니 나머지가 빌 때 «−null · 파일 null개» 가
        // 찍혔다. 규칙을 지키려던 코드가 정작 더 나쁜 표시를 냈다.
        if (changeSummary(pull) case final summary?) ...[
          const SizedBox(height: NxSpacing.sp4),
          Text(summary, style: nx.text.meta),
        ],
        if ((pull.body ?? '').isNotEmpty) ...[
          const SizedBox(height: NxSpacing.sp7),
          MarkdownBody(body: pull.body!),
        ],
        // **`review` 가 `null` 이면 리뷰 칸 자체를 만들지 않는다** — 혼자
        // 쓰는 저장소에서는 늘 비는 값이라, 빈 칸은 잡음이다.
        if (pull.review != null) ...[
          gap,
          Row(
            children: [
              Text('리뷰', style: nx.text.strong),
              const SizedBox(width: NxSpacing.sp4),
              _ReviewChip(review: pull.review!),
            ],
          ),
        ],
        gap,
        Text('바뀐 파일 ${view.files.length}개', style: nx.text.strong),
        const SizedBox(height: NxSpacing.sp4),
        PullFileList(
          files: view.files,
          // **diff 를 그리지 않는다** — 10-3a 의 파일 보기를 head 시점으로
          // 연다(10-3b 의 커밋 상세와 같은 판단).
          //
          // **브랜치 이름이 아니라 sha 다.** 포크에서 온 PR 의 head 브랜치는
          // 포크 쪽에 있어 우리가 붙인 저장소의 contents API 가 404 를 준다 —
          // 진짜 GitHub 으로 확인했다(브랜치 404 · sha 200). sha 는 불변이라
          // 그 뒤에 push 가 와도 리뷰한 그 시점을 가리킨다. sha 가 없는
          // 응답에서만 브랜치로 떨어진다.
          onTap: (f) => context.push(
            '/s/$spaceId/repos/$repoId/browse'
            '?ref=${Uri.encodeQueryComponent(pull.headSha ?? pull.sourceBranch ?? '')}'
            '&path=${Uri.encodeQueryComponent(f.path)}',
          ),
        ),
        // **`truncated` 면 조용히 자르지 않는다.**
        if (view.truncated) ...[
          const SizedBox(height: NxSpacing.sp4),
          Text('파일이 많아 300개까지만 보여 줍니다.', style: nx.text.secondary),
          if (pull.htmlUrl != null)
            Align(
              alignment: Alignment.centerLeft,
              child: NxButton(
                label: 'GitHub 에서 보기',
                kind: NxButtonKind.ghost,
                size: NxSize.sm,
                onPressed: () => launchUrl(
                  Uri.parse(pull.htmlUrl!),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
