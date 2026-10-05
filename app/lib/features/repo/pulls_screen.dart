import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/pull.dart';
import '../../shared/widgets/back_button.dart';
import '../../ui/ui.dart';
import 'browse_controller.dart';

typedef PullListKey = ({String spaceId, String repoId, String state});

/// PR 목록 첫 장. `state` 가 바뀌면(열림 ↔ 닫힘) 새로 부른다. 다음 장은 이
/// provider 가 아니라 `_PullsScreenState` 가 직접 이어 붙인다 — 커밋 목록과
/// 같은 이유다: 필터 전환은 목록을 통째로 바꾸는 일이고, 더 불러오기는 그
/// 위에 쌓는 일이라 성격이 다르다.
///
/// **`autoDispose` 다.** PR 은 캐시하지 않는다 — 파일 목록 · 이슈 상세 · 댓글 ·
/// 라벨 · 번다운과 같은 취급이다. 빼 두었더니 화면을 떠나도 결과가 남아,
/// GitHub 에서 머지된 PR 이 다시 들어와도 「열림」 으로 굳어 있었다. 나가서
/// 다시 들어오는 것이 곧 새로고침이 된다.
final pullsProvider = FutureProvider.autoDispose
    .family<({List<PullSummary> pulls, int? nextPage}), PullListKey>(
      (ref, key) => ref
          .read(pullsApiProvider)
          .list(key.spaceId, key.repoId, state: key.state),
    );

/// PR 상태 표지. 목록과 상세가 같이 쓴다. **`draft` 가 상태보다 먼저다** —
/// 초안은 열림 안의 하위 상태라 그대로 두면 "열림"으로 오해한다.
///
/// 색만으로 말하지 않게 점과 글자를 함께 쓴다(디자인 시스템 §6).
class PullStateChip extends StatelessWidget {
  const PullStateChip({super.key, required this.state, this.draft = false});

  final PullState state;
  final bool draft;

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    if (draft) return NxTag('초안', dot: true, color: c.warning);
    final (label, color) = switch (state) {
      PullState.open => ('열림', c.success),
      PullState.merged => ('머지됨', c.merged),
      PullState.closed => ('닫힘', c.danger),
    };
    return NxTag(label, dot: true, color: color);
  }
}

/// PR 목록. **변경량을 그리지 않는다** — 서버가 목록 응답에 싣지 않는다
/// (설계 §1).
class PullList extends StatelessWidget {
  const PullList({
    super.key,
    required this.pulls,
    required this.onTap,
    this.state = 'open',
    this.onMore,
    this.loadingMore = false,
  });

  final List<PullSummary> pulls;

  /// 빈 목록 문구가 필터를 따라가야 한다. 「닫힘」 을 골랐는데 «열린 PR 이
  /// 없습니다» 라고 하면 필터가 안 먹은 것으로 읽힌다.
  final String state;
  final void Function(PullSummary pull) onTap;
  final VoidCallback? onMore;

  /// 이어 받는 중. **자리를 지킨 채 작은 호로 바꾼다** — 사라지면 목록이 튀고,
  /// 누른 것이 먹었는지 알 수 없다.
  final bool loadingMore;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    if (pulls.isEmpty) {
      return Center(
        child: Text(
          state == 'closed' ? '닫힌 PR 이 없습니다' : '열린 PR 이 없습니다',
          style: nx.text.secondary,
        ),
      );
    }

    final hasMoreRow = onMore != null || loadingMore;

    return ListView.builder(
      itemCount: pulls.length + (hasMoreRow ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == pulls.length) {
          return SizedBox(
            height: 44,
            child: Center(
              child: loadingMore
                  ? const NxSpinner(size: NxIconSize.md)
                  : NxButton(
                      label: '더 불러오기',
                      kind: NxButtonKind.ghost,
                      onPressed: onMore,
                    ),
            ),
          );
        }
        return _PullRow(pull: pulls[i], onPressed: () => onTap(pulls[i]));
      },
    );
  }
}

class _PullRow extends StatelessWidget {
  const _PullRow({required this.pull, required this.onPressed});

  final PullSummary pull;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return NxHoverSurface(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(
        horizontal: NxSpacing.inset,
        vertical: NxSpacing.sp4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '#${pull.number}',
                        style: nx.text.mono.copyWith(fontSize: NxFontSize.sm),
                      ),
                      const TextSpan(text: ' · '),
                      TextSpan(text: pull.title),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nx.text.base,
                ),
                const SizedBox(height: NxSpacing.sp1),
                Text(
                  '${pull.sourceBranch ?? '?'} → ${pull.targetBranch ?? '?'}',
                  overflow: TextOverflow.ellipsis,
                  style: nx.text.mono,
                ),
              ],
            ),
          ),
          const SizedBox(width: NxSpacing.sp4),
          PullStateChip(state: pull.state, draft: pull.draft),
        ],
      ),
    );
  }
}

/// PR 목록 화면. 열림 · 닫힘(머지 포함) 필터를 세그먼트로 둔다.
class PullsScreen extends ConsumerStatefulWidget {
  const PullsScreen({super.key, required this.spaceId, required this.repoId});

  final String spaceId;
  final String repoId;

  @override
  ConsumerState<PullsScreen> createState() => _PullsScreenState();
}

class _PullsScreenState extends ConsumerState<PullsScreen> {
  var _state = 'open';

  // 첫 장은 pullsProvider 가 준다. 그 뒤 장은 여기서 이어 붙인다.
  final _extra = <PullSummary>[];
  int? _extraNextPage;
  var _loadingMore = false;

  /// **다음 장 번호를 `_extra` 가 비었는지로 고르면 안 된다.** 이어 받은 장이
  /// 빈 배열이면 `_extra` 가 그대로 비어 첫 장의 `nextPage` 로 되돌아가고,
  /// 버튼이 사라지지 않은 채 같은 장을 무한히 다시 부른다 — PR 이 정확히
  /// 30건일 때(2장이 빈 배열) 실제로 걸린다. 한 번이라도 이어 받았는지를
  /// 따로 들고 있어야 한다.
  var _pagedOnce = false;

  PullListKey get _key =>
      (spaceId: widget.spaceId, repoId: widget.repoId, state: _state);

  void _changeState(String state) {
    if (state == _state) return;
    setState(() {
      _state = state;
      _extra.clear();
      _extraNextPage = null;
      _pagedOnce = false;
    });
  }

  Future<void> _loadMore(int page) async {
    setState(() => _loadingMore = true);
    try {
      final res = await ref
          .read(pullsApiProvider)
          .list(widget.spaceId, widget.repoId, state: _state, page: page);
      if (!mounted) return;
      setState(() {
        _extra.addAll(res.pulls);
        _extraNextPage = res.nextPage;
        // 빈 장을 받아도 «이어 받았다»는 사실은 남는다. 이것이 없으면
        // 다음 장 번호가 첫 장의 것으로 되돌아간다.
        _pagedOnce = true;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pullsProvider(_key));

    return NxPage(
      header: NxHeader(
        title: 'Pull Request',
        leading: NxBackButton(
          fallback: '/s/${widget.spaceId}/repos/${widget.repoId}/browse',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          NxSpacing.sp5,
          NxSpacing.sp6,
          NxSpacing.sp5,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NxSpacing.inset),
              child: NxSegmented<String>(
                label: 'PR 상태',
                expand: false,
                value: _state,
                segments: const [('open', '열림'), ('closed', '닫힘')],
                onChanged: _changeState,
              ),
            ),
            const SizedBox(height: NxSpacing.sp5),
            Expanded(child: _body(async)),
          ],
        ),
      ),
    );
  }

  Widget _body(AsyncValue<({List<PullSummary> pulls, int? nextPage})> async) {
    // 재시도 중(「로딩 + 오류」)에도 오류를 보인다 — 저장소 화면과 같은 이유.
    return switch (async) {
      _ when async.hasError => _PullsError(
        error: async.error!,
        spaceId: widget.spaceId,
        onRetry: () => ref.invalidate(pullsProvider(_key)),
      ),
      AsyncData(:final value) => () {
        final nextPage = _pagedOnce ? _extraNextPage : value.nextPage;
        return PullList(
          pulls: [...value.pulls, ..._extra],
          state: _state,
          // 이어 받는 중에는 `onMore` 를 끊어 두 번 눌리지 않게 하되,
          // 행 자체는 `loadingMore` 가 지킨다.
          onMore: _loadingMore || nextPage == null
              ? null
              : () => _loadMore(nextPage),
          loadingMore: _loadingMore,
          onTap: (p) => context.push(
            '/s/${widget.spaceId}/repos/${widget.repoId}/pulls/${p.number}',
          ),
        );
      }(),
      _ => const Padding(
        padding: EdgeInsets.all(NxSpacing.inset),
        child: NxSkeleton(lines: 5, lineHeight: 36),
      ),
    };
  }
}

/// 목록을 못 받았을 때. **가장 흔한 원인은 GitHub 미연결이다** — 저장소를
/// 붙인 뒤 나중에 연결을 해제하면(10-2a) 서버가 400 을 준다.
///
/// 예전에는 400 이 `ApiFailure.server` 로 접혀 **진짜 서버 오류에도 «GitHub 을
/// 연결하세요» 가 떴다.** 이제 `badRequest` 로 갈라져, 그 경우에만 연결하러
/// 가는 길을 보여 준다. 그 밖의 실패(찾을 수 없음 · 네트워크 · 서버 오류)는
/// 다시 확인으로 충분하다.
class _PullsError extends StatelessWidget {
  const _PullsError({
    required this.error,
    required this.spaceId,
    required this.onRetry,
  });

  final Object error;
  final String spaceId;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error is ApiException
        ? (error as ApiException).failure
        : null;

    if (failure != ApiFailure.badRequest) {
      return _Message(
        text: failure == null
            ? messageFor(ApiFailure.server)
            : messageFor(failure),
        action: NxButton(
          label: '다시 확인',
          kind: NxButtonKind.secondary,
          onPressed: onRetry,
        ),
      );
    }

    return _Message(
      text: 'GitHub 을 연결하세요',
      action: NxButton(
        label: '저장소 화면으로',
        // **`push` 가 아니라 `go` 다.** 여기는 셸 밖이고 저장소 화면은 셸
        // 안이라, `push` 하면 `ShellRoute` 가 두 번 쌓여 페이지 키가 겹친다
        // (`test/router_shell_test.dart`). 뜻으로 봐도 `go` 가 맞다 —
        // 연결하러 가는 것이지 PR 목록 위에 얹어 보고 돌아올 일이 아니다.
        onPressed: () => context.go('/s/$spaceId/repos'),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.action});

  final String text;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: NxTheme.of(context).text.base),
          const SizedBox(height: NxSpacing.sp4),
          action,
        ],
      ),
    );
  }
}
