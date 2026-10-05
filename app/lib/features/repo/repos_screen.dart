import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shell/app_shell.dart';
import '../../data/socket/socket_event.dart';
import '../../domain/models/connection.dart';
import '../../domain/models/repo.dart';
import '../../ui/ui.dart';
import '../realtime/socket_controller.dart';
import 'connection_controller.dart';
import 'repo_controller.dart';
import 'repo_picker_sheet.dart';

/// 저장소 화면 — 위는 GitHub 연결, 아래는 붙은 저장소 목록.
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
          : await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
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

  void _toast(String message) =>
      NxToast.show(context, message, kind: NxToastKind.error);

  Future<void> _openPicker(String login) async {
    // 바텀시트가 아니라 가운데 패널이다(15단계 D8).
    final added = await NxDialog.panel<bool>(
      context,
      title: '@$login 의 저장소',
      width: 520,
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

    final nx = NxTheme.of(context);
    final connections = ref.watch(connectionsProvider);
    final github = ref.watch(githubConnectionProvider);

    return NxPage(
      header: const ShellHeader(title: '저장소'),
      body: ListView(
        padding: const EdgeInsets.all(NxSpacing.sp7),
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // **재시도 중에도 오류를 보인다.** Riverpod 3 은 실패한 provider 를 스스로
                  // 다시 부르는데 그동안 상태가 「로딩 + 오류」다 — `AsyncError()` 로만
                  // 가르면 수십 초 동안 뼈대만 보인다(회전 스피너 시절에는 테스트가 그
                  // 시간을 기다려 줘 드러나지 않았다).
                  switch (connections) {
                    _ when connections.hasError => _Retry(
                      onRetry: () => ref.invalidate(connectionsProvider),
                    ),
                    AsyncLoading() => const NxSkeleton(
                      lines: 1,
                      lineHeight: 64,
                    ),
                    _ =>
                      github == null
                          ? _Disconnected(
                              waiting: _waiting,
                              onConnect: _connect,
                            )
                          : _Connected(
                              connection: github,
                              onDisconnect: _disconnect,
                            ),
                  },
                  // **연결 전에는 목록을 부르지 않는다** — 토큰이 없으면 서버가 400 이다.
                  if (github != null) ...[
                    const SizedBox(height: NxSpacing.sp9),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text('붙은 저장소', style: nx.text.strong),
                          ),
                        ),
                        NxButton(
                          label: '저장소 추가',
                          icon: NxIcons.plus,
                          kind: NxButtonKind.secondary,
                          size: NxSize.sm,
                          onPressed: () => _openPicker(github.login),
                        ),
                      ],
                    ),
                    const SizedBox(height: NxSpacing.sp5),
                    switch (ref.watch(spaceReposProvider(widget.spaceId))) {
                      final repos when repos.hasError => _Retry(
                        onRetry: () =>
                            ref.invalidate(spaceReposProvider(widget.spaceId)),
                      ),
                      AsyncValue(:final value?) when value.isEmpty => Text(
                        '아직 붙인 저장소가 없습니다',
                        style: nx.text.secondary,
                      ),
                      AsyncValue(:final value?) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final repo in value)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: NxSpacing.sp4,
                              ),
                              child: _RepoRow(
                                repo: repo,
                                onOpen: () => context.push(
                                  '/s/${widget.spaceId}/repos/${repo.id}/browse',
                                ),
                                onReattach: () => _reattach(repo.id),
                                onRemove: () => _remove(repo.id),
                              ),
                            ),
                        ],
                      ),
                      _ => const NxSkeleton(lines: 2, lineHeight: 56),
                    },
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 표면 한 단 위의 판 — 그림자 없이 표면 색으로만 떠 보인다(§3-13).
class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(NxSpacing.sp6),
    decoration: BoxDecoration(
      color: NxTheme.of(context).colors.bgSurface,
      borderRadius: BorderRadius.circular(NxRadius.md),
    ),
    child: child,
  );
}

class _RepoRow extends StatelessWidget {
  const _RepoRow({
    required this.repo,
    required this.onOpen,
    required this.onReattach,
    required this.onRemove,
  });

  final SpaceRepo repo;

  /// 행을 누르면 저장소 안을 들여다본다(10-3a).
  final VoidCallback onOpen;
  final VoidCallback onReattach;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    return NxHoverSurface(
      onPressed: onOpen,
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp6,
        NxSpacing.sp5,
        NxSpacing.sp4,
        NxSpacing.sp5,
      ),
      base: c.bgSurface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repo.fullPath,
                  overflow: TextOverflow.ellipsis,
                  style: nx.text.strong,
                ),
                const SizedBox(height: NxSpacing.sp2),
                // 훅이 안 걸린 것을 조용히 두면 사용자는 커밋이 왜 안 오는지 모른다.
                NxTag(
                  repo.webhookActive ? '웹훅 연결됨' : '웹훅 등록 실패',
                  dot: true,
                  color: repo.webhookActive ? c.success : c.danger,
                ),
              ],
            ),
          ),
          if (!repo.webhookActive) ...[
            NxButton(
              label: '다시 걸기',
              kind: NxButtonKind.secondary,
              size: NxSize.sm,
              onPressed: onReattach,
            ),
            const SizedBox(width: NxSpacing.sp2),
          ],
          // 떼어 내기는 한 번 더 눌러야 닿게 메뉴 안에 둔다 — 행을 누르려다 빗나가지 않게.
          NxMenu(
            width: 180,
            entries: [NxMenuItem('떼어 내기', danger: true, onSelected: onRemove)],
            anchorBuilder: (context, toggle) => NxIconButton(
              icon: NxIcons.more,
              label: '${repo.fullPath} 더 보기',
              onPressed: toggle,
            ),
          ),
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
    final nx = NxTheme.of(context);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GitHub 을 연결하면 커밋과 PR 이 채널로 들어옵니다', style: nx.text.base),
          const SizedBox(height: NxSpacing.sp5),
          if (waiting)
            Text('브라우저에서 계속하세요…', style: nx.text.secondary)
          else
            NxButton(label: 'GitHub 연결', onPressed: onConnect),
        ],
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
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final initial = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.bgElevated, shape: BoxShape.circle),
      child: Text(
        connection.login.characters.firstOrNull?.toUpperCase() ?? '?',
        style: nx.text.strong,
      ),
    );
    return _Surface(
      child: Row(
        children: [
          connection.avatarUrl == null
              ? initial
              : ClipOval(
                  child: Image.network(
                    connection.avatarUrl!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => initial,
                  ),
                ),
          const SizedBox(width: NxSpacing.sp5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${connection.login}', style: nx.text.strong),
                Text('GitHub 연결됨', style: nx.text.meta),
              ],
            ),
          ),
          NxButton(
            label: '연결 해제',
            kind: NxButtonKind.ghost,
            size: NxSize.sm,
            onPressed: onDisconnect,
          ),
        ],
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
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('연결 상태를 불러오지 못했습니다', style: NxTheme.of(context).text.base),
          const SizedBox(height: NxSpacing.sp4),
          NxButton(
            label: '다시 확인',
            kind: NxButtonKind.secondary,
            size: NxSize.sm,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
