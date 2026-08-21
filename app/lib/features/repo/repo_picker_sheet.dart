import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/channel.dart';
import '../../domain/models/repo.dart';
import '../channel/channel_controller.dart';
import 'repo_controller.dart';

/// 내 GitHub 저장소를 골라 채널에 붙인다.
///
/// **검색은 받아 온 페이지 안에서 한다** — 서버에 검색이 없다(설계 §6).
/// `/user/repos` 에는 검색 파라미터가 없고 `/search/repositories` 는 rate
/// limit 도 응답 모양도 다르다. 저장소가 100개를 넘겨 답답해지면 그때 붙인다.
class RepoPickerSheet extends ConsumerStatefulWidget {
  const RepoPickerSheet({super.key, required this.spaceId, required this.login});

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
      await ref.read(reposApiProvider).connect(
            widget.spaceId,
            githubRepoId: repo.id,
            linkedChannelId: _channelId,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장소를 붙이지 못했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(channelsProvider).value ?? const <Channel>[];
    final shown = _filter.isEmpty
        ? _repos
        : _repos
            .where((r) => r.fullName.toLowerCase().contains(_filter.toLowerCase()))
            .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${widget.login} 의 저장소',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '이름으로 거르기',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 12),
            // 채널을 고르지 않으면 이벤트를 적재만 하고 채널에는 올리지 않는다.
            DropdownButtonFormField<String?>(
              initialValue: _channelId,
              decoration: const InputDecoration(
                labelText: '올릴 채널 (고르지 않으면 적재만 한다)',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('채널 없음')),
                for (final c in channels)
                  DropdownMenuItem<String?>(value: c.id, child: Text('#${c.name}')),
              ],
              onChanged: (v) => setState(() => _channelId = v),
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(_error!),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _load, child: const Text('다시 확인')),
              const SizedBox(height: 8),
            ],
            Flexible(
              child: _loading && _repos.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: shown.length + (_hasNext ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == shown.length) {
                          return TextButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    _page++;
                                    _load();
                                  },
                            child: const Text('더 불러오기'),
                          );
                        }
                        final repo = shown[i];
                        // 권한이 없으면 고를 수 없게 한다 — 눌러 봐야 403 이다
                        // (7-5 에서 답글 고정을 시트에서 감춘 것과 같은 판단).
                        return ListTile(
                          enabled: repo.canWebhook,
                          title: Text(repo.fullName),
                          subtitle: Text(
                            repo.canWebhook
                                ? (repo.private ? '비공개' : '공개')
                                : '웹훅 권한이 없습니다',
                          ),
                          onTap: repo.canWebhook ? () => _connect(repo) : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
