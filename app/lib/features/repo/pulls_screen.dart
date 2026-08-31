import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api/api_failure.dart';
import '../../domain/models/pull.dart';
import 'browse_controller.dart';

typedef PullListKey = ({String spaceId, String repoId, String state});

/// PR 목록 첫 장. `state` 가 바뀌면(열림 ↔ 닫힘) 새로 부른다. 다음 장은 이
/// provider 가 아니라 `_PullsScreenState` 가 직접 이어 붙인다 — 커밋 목록과
/// 같은 이유다: 필터 전환은 목록을 통째로 바꾸는 일이고, 더 불러오기는 그
/// 위에 쌓는 일이라 성격이 다르다.
final pullsProvider =
    FutureProvider.family<({List<PullSummary> pulls, int? nextPage}), PullListKey>(
  (ref, key) =>
      ref.read(pullsApiProvider).list(key.spaceId, key.repoId, state: key.state),
);

/// PR 상태 칩. 목록과 상세가 같이 쓴다. **`draft` 가 상태보다 먼저다** —
/// 초안은 열림 안의 하위 상태라 그대로 두면 "열림"으로 오해한다.
class PullStateChip extends StatelessWidget {
  const PullStateChip({super.key, required this.state, this.draft = false});

  final PullState state;
  final bool draft;

  @override
  Widget build(BuildContext context) {
    if (draft) {
      return Chip(
        label: const Text('초안'),
        labelStyle: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: NexusColors.warning),
      );
    }
    final (label, color) = switch (state) {
      PullState.open => ('열림', NexusColors.success),
      PullState.merged => ('머지됨', NexusColors.merged),
      PullState.closed => ('닫힘', NexusColors.danger),
    };
    return Chip(
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    );
  }
}

/// PR 목록. **변경량을 그리지 않는다** — 서버가 목록 응답에 싣지 않는다
/// (설계 §1).
class PullList extends StatelessWidget {
  const PullList({
    super.key,
    required this.pulls,
    required this.onTap,
    this.onMore,
  });

  final List<PullSummary> pulls;
  final void Function(PullSummary pull) onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    if (pulls.isEmpty) return const Center(child: Text('열린 PR 이 없습니다'));

    return ListView.builder(
      itemCount: pulls.length + (onMore == null ? 0 : 1),
      itemBuilder: (_, i) {
        if (i == pulls.length) {
          return TextButton(onPressed: onMore, child: const Text('더 불러오기'));
        }

        final p = pulls[i];
        return ListTile(
          dense: true,
          title: Text(
            '#${p.number} · ${p.title}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('${p.sourceBranch ?? '?'} → ${p.targetBranch ?? '?'}'),
          trailing: PullStateChip(state: p.state, draft: p.draft),
          onTap: () => onTap(p),
        );
      },
    );
  }
}

/// PR 목록 화면. 열림 · 닫힘(머지 포함) 필터를 `SegmentedButton` 으로 둔다.
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

  PullListKey get _key =>
      (spaceId: widget.spaceId, repoId: widget.repoId, state: _state);

  void _changeState(String state) {
    if (state == _state) return;
    setState(() {
      _state = state;
      _extra.clear();
      _extraNextPage = null;
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

    return Scaffold(
      appBar: AppBar(title: const Text('Pull Request')),
      body: Padding(
        padding: const EdgeInsets.all(NexusSpacing.sp6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'open', label: Text('열림')),
                ButtonSegment(value: 'closed', label: Text('닫힘')),
              ],
              selected: {_state},
              onSelectionChanged: (s) => _changeState(s.first),
            ),
            const SizedBox(height: NexusSpacing.sp6),
            Expanded(child: _body(async)),
          ],
        ),
      ),
    );
  }

  Widget _body(AsyncValue<({List<PullSummary> pulls, int? nextPage})> async) {
    return switch (async) {
      AsyncError(:final error) => _PullsError(
          error: error,
          spaceId: widget.spaceId,
          onRetry: () => ref.invalidate(pullsProvider(_key)),
        ),
      AsyncData(:final value) => PullList(
          pulls: [...value.pulls, ..._extra],
          onMore: _loadingMore
              ? null
              : (_extra.isEmpty ? value.nextPage : _extraNextPage) == null
                  ? null
                  : () => _loadMore(
                      (_extra.isEmpty ? value.nextPage : _extraNextPage)!),
          onTap: (p) => context.push(
            '/s/${widget.spaceId}/repos/${widget.repoId}/pulls/${p.number}',
          ),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// 목록을 못 받았을 때. **가장 흔한 원인은 GitHub 미연결이다** — 저장소를
/// 붙인 뒤 나중에 연결을 해제하면(10-2a) 서버가 400 을 주는데, 그 실패는
/// `ApiFailure.server` 로 접힌다(400 은 classifyDioException 이 딱히 갈래를
/// 두지 않은 코드다). 그 밖의 실패(찾을 수 없음 · 네트워크)는 다시 확인으로
/// 충분하다.
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
    final failure = error is ApiException ? (error as ApiException).failure : null;

    if (failure != null && failure != ApiFailure.server) {
      return _Message(
        text: messageFor(failure),
        action: OutlinedButton(onPressed: onRetry, child: const Text('다시 확인')),
      );
    }

    return _Message(
      text: 'GitHub 을 연결하세요',
      action: FilledButton(
        onPressed: () => context.push('/s/$spaceId/repos'),
        child: const Text('저장소 화면으로'),
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
          Text(text),
          const SizedBox(height: NexusSpacing.sp4),
          action,
        ],
      ),
    );
  }
}
