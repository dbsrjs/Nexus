import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/socket/socket_event.dart';
import '../../domain/models/connection.dart';
import '../../domain/models/repo.dart';
import '../realtime/socket_controller.dart';
import 'connection_controller.dart';
import 'repo_controller.dart';
import 'repo_picker_sheet.dart';

/// 저장소 화면. **10-2a 는 상단 연결 영역만 채운다** — 저장소 목록과
/// 붙이기는 10-2b 다.
class ReposScreen extends ConsumerStatefulWidget {
  const ReposScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<ReposScreen> createState() => _ReposScreenState();
}

class _ReposScreenState extends ConsumerState<ReposScreen> {
  /// 브라우저를 열어 둔 상태. **타임아웃을 두지 않는다** — 사람이 GitHub
  /// 로그인부터 해야 할 수도 있어 얼마가 걸릴지 알 수 없다 (설계 §9).
  bool _waiting = false;

  Future<void> _connect() async {
    setState(() => _waiting = true);
    try {
      final url = await ref.read(connectionsApiProvider).startGithub();
      final ok = url.isEmpty
          ? false
          : await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        setState(() => _waiting = false);
        _toast('브라우저를 열지 못했습니다');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _waiting = false);
      _toast('연결을 시작하지 못했습니다');
    }
  }

  Future<void> _disconnect() async {
    try {
      await ref.read(connectionsApiProvider).disconnectGithub();
    } catch (_) {
      if (mounted) _toast('해제하지 못했습니다');
    }
    ref.invalidate(connectionsProvider);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPicker(String login) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RepoPickerSheet(spaceId: widget.spaceId, login: login),
    );
    if (added == true) ref.invalidate(spaceReposProvider(widget.spaceId));
  }

  Future<void> _reattach(String repoId) async {
    try {
      await ref.read(reposApiProvider).reattach(widget.spaceId, repoId);
    } catch (_) {
      if (mounted) _toast('웹훅을 걸지 못했습니다');
    }
    ref.invalidate(spaceReposProvider(widget.spaceId));
  }

  Future<void> _remove(String repoId) async {
    try {
      await ref.read(reposApiProvider).remove(widget.spaceId, repoId);
    } catch (_) {
      if (mounted) _toast('떼어 내지 못했습니다');
    }
    ref.invalidate(spaceReposProvider(widget.spaceId));
  }

  @override
  Widget build(BuildContext context) {
    // 콜백은 브라우저가 받는다. 앱은 이 이벤트로 연결을 안다.
    // socketEventsProvider 는 features/realtime/socket_controller.dart:34 다.
    ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (_, next) {
      if (next.value is! OauthConnected) return;
      if (mounted) setState(() => _waiting = false);
      ref.invalidate(connectionsProvider);
    });

    final connections = ref.watch(connectionsProvider);
    final github = ref.watch(githubConnectionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('저장소')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          switch (connections) {
            AsyncError() => _Retry(onRetry: () => ref.invalidate(connectionsProvider)),
            AsyncLoading() => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            _ => github == null
                ? _Disconnected(waiting: _waiting, onConnect: _connect)
                : _Connected(connection: github, onDisconnect: _disconnect),
          },
          // **연결 전에는 목록을 부르지 않는다** — 토큰이 없으면 서버가 400 이다.
          if (github != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('붙은 저장소',
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                TextButton.icon(
                  onPressed: () => _openPicker(github.login),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('저장소 추가'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            switch (ref.watch(spaceReposProvider(widget.spaceId))) {
              AsyncError() => _Retry(
                  onRetry: () =>
                      ref.invalidate(spaceReposProvider(widget.spaceId)),
                ),
              AsyncLoading() => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              AsyncValue(:final value?) when value.isEmpty =>
                const Text('아직 붙인 저장소가 없습니다'),
              AsyncValue(:final value?) => Column(
                  children: [
                    for (final repo in value)
                      _RepoRow(
                        repo: repo,
                        onReattach: () => _reattach(repo.id),
                        onRemove: () => _remove(repo.id),
                      ),
                  ],
                ),
            },
          ],
        ],
      ),
    );
  }
}

class _RepoRow extends StatelessWidget {
  const _RepoRow({
    required this.repo,
    required this.onReattach,
    required this.onRemove,
  });

  final SpaceRepo repo;
  final VoidCallback onReattach;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(repo.fullPath),
        // 훅이 안 걸린 것을 조용히 두면 사용자는 커밋이 왜 안 오는지 모른다.
        subtitle: Text(repo.webhookActive ? '웹훅 연결됨' : '웹훅 등록 실패'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!repo.webhookActive)
              TextButton(onPressed: onReattach, child: const Text('다시 걸기')),
            IconButton(
              tooltip: '떼어 내기',
              icon: const Icon(Icons.link_off, size: 18),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _Disconnected extends StatelessWidget {
  const _Disconnected({required this.waiting, required this.onConnect});

  final bool waiting;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GitHub 을 연결하면 커밋과 PR 이 채널로 들어옵니다',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            if (waiting)
              const Text('브라우저에서 계속하세요…')
            else
              FilledButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.link, size: 18),
                label: const Text('GitHub 연결'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Connected extends StatelessWidget {
  const _Connected({required this.connection, required this.onDisconnect});

  final GithubConnection connection;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: connection.avatarUrl == null
              ? null
              : NetworkImage(connection.avatarUrl!),
          child: connection.avatarUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text('@${connection.login}'),
        subtitle: const Text('GitHub 연결됨'),
        trailing: TextButton(onPressed: onDisconnect, child: const Text('연결 해제')),
      ),
    );
  }
}

/// 조용히 빈 화면을 그리면 "연결 안 됨"과 구분되지 않는다.
class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('연결 상태를 불러오지 못했습니다'),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('다시 확인')),
      ],
    );
  }
}
