import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/ai_thread.dart';
import '../../domain/models/channel.dart';
import '../../shared/markdown/plain_text.dart';
import '../../ui/ui.dart';
import '../channel/channel_controller.dart';
import '../channel/dm.dart';
import '../notifications/notifications_screen.dart' show notificationTime;
import '../repo/repo_controller.dart';
import 'ai_controller.dart';

/// AI 패널의 「지난 대화」(19 설계 §3). 사슬 하나가 한 줄이고, 누르면 그 사슬을
/// 받아 [onOpen] 으로 넘긴다 — 문답 화면으로 옮기는 것은 패널의 일이다.
///
/// **페이지 상태를 이 위젯이 든다.** 캐시하지 않는다(설계 D13) — 패널과 함께
/// 사라지고 다시 열면 새로 읽는다.
class AiHistoryList extends ConsumerStatefulWidget {
  const AiHistoryList({
    super.key,
    required this.spaceId,
    required this.onOpen,
    required this.onBack,
  });

  final String spaceId;
  final ValueChanged<AiThread> onOpen;

  /// 「새 질문」 — 원래 칩으로 입력 화면에 돌아간다.
  final VoidCallback onBack;

  @override
  ConsumerState<AiHistoryList> createState() => _AiHistoryListState();
}

class _AiHistoryListState extends ConsumerState<AiHistoryList> {
  final List<AiThreadSummary> _items = [];
  String? _cursor;
  bool _loading = false;

  /// 첫 페이지를 못 받았을 때. 더 보기의 실패는 토스트로만 알린다 — 받아 둔 줄을 지우지 않는다.
  ApiFailure? _failure;

  /// 처음 한 번이라도 받았는가. 받기 전에는 뼈대를 보인다.
  bool _loaded = false;

  /// 지금 여는 중인 사슬 — 그 줄에만 스피너를 두고 다른 줄은 막는다.
  String? _opening;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (!more) _failure = null;
    });
    try {
      final page = await ref
          .read(aiApiProvider)
          .listThreads(widget.spaceId, cursor: more ? _cursor : null);
      if (!mounted) return;
      setState(() {
        if (!more) _items.clear();
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _loaded = true;
      });
    } on ApiException catch (err) {
      if (!mounted) return;
      if (more) {
        NxToast.show(context, '더 불러오지 못했습니다', kind: NxToastKind.error);
      } else {
        setState(() => _failure = err.failure);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(AiThreadSummary item) async {
    if (_opening != null) return;
    setState(() => _opening = item.rootRunId);
    try {
      final thread = await ref
          .read(aiApiProvider)
          .getThread(widget.spaceId, item.rootRunId);
      if (!mounted) return;
      widget.onOpen(thread);
    } on ApiException catch (err) {
      if (!mounted) return;
      // 그사이 볼 수 없게 됐다(비공개 명단에서 빠짐 등) — 목록에서도 뺀다.
      if (err.failure == ApiFailure.notFound) {
        setState(
          () => _items.removeWhere((i) => i.rootRunId == item.rootRunId),
        );
      }
      NxToast.show(context, '대화를 열지 못했습니다', kind: NxToastKind.error);
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final channels = {
      for (final c in ref.watch(channelsProvider).value ?? const <Channel>[])
        c.id: c,
    };
    final members = ref.watch(memberProfilesProvider);
    final repos = {
      for (final r
          in ref.watch(spaceReposProvider(widget.spaceId)).value ?? const [])
        r.id: r.name,
    };

    /// 무엇을 근거로 물었는지 — 이름을 모르면 일반 이름(설계 D10).
    String basis(AiThreadSummary item) {
      final parts = <String>[];
      if (item.channelId != null) {
        final channel = channels[item.channelId];
        parts.add(
          channel == null
              ? '채널'
              : channel.isDm
              ? dmPeerName(members, channel)
              : '#${channel.name}',
        );
      }
      if (item.repoId != null) parts.add(repos[item.repoId] ?? '저장소');
      return parts.join(' · ');
    }

    final Widget body;
    if (!_loaded && _failure == null) {
      body = const NxSkeleton(lines: 4, lineHeight: 40);
    } else if (_failure != null) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _failure == ApiFailure.network
                ? '연결이 없어 지난 대화를 불러오지 못했습니다.'
                : '지난 대화를 불러오지 못했습니다.',
            style: nx.text.secondary,
          ),
          const SizedBox(height: NxSpacing.sp4),
          Align(
            alignment: Alignment.centerLeft,
            child: NxButton(
              label: '다시 시도',
              kind: NxButtonKind.secondary,
              size: NxSize.sm,
              onPressed: _load,
            ),
          ),
        ],
      );
    } else if (_items.isEmpty) {
      body = Text('지난 대화가 없습니다.', style: nx.text.secondary);
    } else {
      body = Flexible(
        child: ListView(
          shrinkWrap: true,
          // 다이얼로그 안 목록 — 기기 안전 영역 여백을 가져오지 않는다(CLAUDE.md §2).
          padding: EdgeInsets.zero,
          children: [
            for (final item in _items)
              _ThreadRow(
                key: ValueKey(item.rootRunId),
                item: item,
                meta: [
                  basis(item),
                  '문답 ${item.turnCount}',
                  notificationTime(item.lastAt),
                ].where((s) => s.isNotEmpty).join(' · '),
                opening: _opening == item.rootRunId,
                onPressed: _opening == null ? () => _open(item) : null,
              ),
            if (_cursor != null) ...[
              const SizedBox(height: NxSpacing.sp4),
              Align(
                child: NxButton(
                  label: '더 보기',
                  kind: NxButtonKind.ghost,
                  size: NxSize.sm,
                  loading: _loading,
                  onPressed: () => _load(more: true),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp7,
        0,
        NxSpacing.sp7,
        NxSpacing.sp7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NxButton(
                label: '새 질문',
                icon: NxIcons.back,
                kind: NxButtonKind.ghost,
                size: NxSize.sm,
                onPressed: widget.onBack,
              ),
              const Spacer(),
              Text('지난 대화', style: nx.text.label),
            ],
          ),
          const SizedBox(height: NxSpacing.sp5),
          body,
        ],
      ),
    );
  }
}

/// 지난 대화 한 줄 — 질문 · 끝 답 미리보기 · 근거와 문답 수. [NxRow] 와 같은 표면이되
/// **줄마다 한 줄로 자른다** — 지시문은 2000자까지 올 수 있다.
class _ThreadRow extends StatelessWidget {
  const _ThreadRow({
    super.key,
    required this.item,
    required this.meta,
    required this.opening,
    required this.onPressed,
  });

  final AiThreadSummary item;
  final String meta;
  final bool opening;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final preview = toPlainText(item.preview).replaceAll('\n', ' ').trim();

    Widget line(String text, TextStyle style) =>
        Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);

    return NxPressable(
      onPressed: onPressed,
      builder: (context, s) => AnimatedContainer(
        duration: NxMotion.micro,
        padding: const EdgeInsets.symmetric(
          horizontal: NxSpacing.inset,
          vertical: NxSpacing.sp3,
        ),
        decoration: BoxDecoration(
          color: s.hovered || s.pressed ? c.bgElevated : NxColors.transparent,
          borderRadius: BorderRadius.circular(NxRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  line(item.title, nx.text.base.copyWith(color: c.textPrimary)),
                  if (preview.isNotEmpty) line(preview, nx.text.secondary),
                  line(meta, nx.text.meta),
                ],
              ),
            ),
            if (opening) ...[
              const SizedBox(width: NxSpacing.sp4),
              const NxSpinner(size: NxIconSize.sm),
            ],
          ],
        ),
      ),
    );
  }
}
