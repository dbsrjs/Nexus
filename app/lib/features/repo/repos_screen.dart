import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/socket/socket_event.dart';
import '../../domain/models/connection.dart';
import '../realtime/socket_controller.dart';
import 'connection_controller.dart';

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
        ],
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
