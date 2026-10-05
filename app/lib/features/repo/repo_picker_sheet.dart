import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/channel.dart';
import '../../domain/models/repo.dart';
import '../../ui/ui.dart';
import '../channel/channel_controller.dart';
import 'repo_controller.dart';

/// 내 GitHub 저장소를 골라 채널에 붙인다. [NxDialog.panel] 안에 뜬다 — 붙이면
/// `true` 를 돌려주며 닫힌다.
///
/// **검색은 받아 온 페이지 안에서 한다** — 서버에 검색이 없다(설계 §6).
/// `/user/repos` 에는 검색 파라미터가 없고 `/search/repositories` 는 rate
/// limit 도 응답 모양도 다르다. 저장소가 100개를 넘겨 답답해지면 그때 붙인다.
class RepoPickerSheet extends ConsumerStatefulWidget {
  const RepoPickerSheet({
    super.key,
    required this.spaceId,
    required this.login,
  });

  final String spaceId;
  final String login;

  @override
  ConsumerState<RepoPickerSheet> createState() => _RepoPickerSheetState();
}

class _RepoPickerSheetState extends ConsumerState<RepoPickerSheet> {
  final _repos = <GithubRepo>[];
  var _page = 1;
  var _hasNext = false;
  var _loading = true;
  var _filter = '';
  String? _channelId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(reposApiProvider).myGithubRepos(_page);
      if (!mounted) return;
      setState(() {
        _repos.addAll(res.repos);
        _hasNext = res.hasNext;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '저장소 목록을 불러오지 못했습니다';
      });
    }
  }

  Future<void> _connect(GithubRepo repo) async {
    try {
      await ref
          .read(reposApiProvider)
          .connect(
            widget.spaceId,
            githubRepoId: repo.id,
            linkedChannelId: _channelId,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      NxToast.show(context, '저장소를 붙이지 못했습니다', kind: NxToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    // DM 에는 저장소를 잇지 않는다(17단계 D13 — 서버도 404).
    final channels = (ref.watch(channelsProvider).value ?? const <Channel>[])
        .where((c) => !c.isDm)
        .toList(growable: false);
    final shown = _filter.isEmpty
        ? _repos
        : _repos
              .where(
                (r) => r.fullName.toLowerCase().contains(_filter.toLowerCase()),
              )
              .toList(growable: false);

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
          NxField(
            hint: '이름으로 거르기',
            dense: true,
            autofocus: true,
            leading: NxIcon(
              NxIcons.search,
              size: NxIconSize.sm,
              color: c.textSecondary,
            ),
            onChanged: (v) => setState(() => _filter = v),
          ),
          const SizedBox(height: NxSpacing.sp6),
          // 채널을 고르지 않으면 이벤트를 적재만 하고 채널에는 올리지 않는다.
          Text(
            '올릴 채널 — 고르지 않으면 적재만 한다',
            style: nx.text.meta.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: NxSpacing.sp3),
          NxSelect<String?>(
            width: 456,
            value: _channelId,
            options: [
              (null, '채널 없음'),
              for (final channel in channels) (channel.id, '#${channel.name}'),
            ],
            onChanged: (v) => setState(() => _channelId = v),
          ),
          const SizedBox(height: NxSpacing.sp6),
          if (_error != null) ...[
            Text(_error!, style: nx.text.secondary.copyWith(color: c.danger)),
            const SizedBox(height: NxSpacing.sp4),
            Align(
              alignment: Alignment.centerLeft,
              child: NxButton(
                label: '다시 확인',
                kind: NxButtonKind.secondary,
                size: NxSize.sm,
                onPressed: _load,
              ),
            ),
            const SizedBox(height: NxSpacing.sp4),
          ],
          Flexible(
            child: _loading && _repos.isEmpty
                ? const NxSkeleton(lines: 4, lineHeight: 40)
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: shown.length + (_hasNext ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == shown.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: NxSpacing.sp4),
                          child: NxButton(
                            label: '더 불러오기',
                            kind: NxButtonKind.ghost,
                            loading: _loading,
                            onPressed: () {
                              _page++;
                              _load();
                            },
                          ),
                        );
                      }
                      final repo = shown[i];
                      // 권한이 없으면 고를 수 없게 한다 — 눌러 봐야 403 이다
                      // (7-5 에서 답글 고정을 시트에서 감춘 것과 같은 판단).
                      return NxRow(
                        title: repo.fullName,
                        subtitle: repo.canWebhook
                            ? (repo.private ? '비공개' : '공개')
                            : '웹훅 권한이 없습니다',
                        titleStyle: repo.canWebhook
                            ? null
                            : nx.text.base.copyWith(color: c.borderStrong),
                        onPressed: repo.canWebhook
                            ? () => _connect(repo)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
