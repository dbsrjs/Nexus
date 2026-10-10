import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/space.dart';
import '../../shared/widgets/nexus_avatar.dart';
import '../../ui/ui.dart';
import '../auth/auth_controller.dart';
import '../settings/theme_controller.dart';
import 'members_controller.dart';
import 'space_controller.dart';
import 'space_dialogs.dart';

/// `/spaces` — 어느 스페이스로 들어갈지 고른다.
///
/// 아래에 스페이스 만들기 · 초대 코드로 참여(16단계 설계 D1 · D2)를 둔다. 처음 가입한
/// 사람은 목록이 비어 있으니 이 둘이 첫 화면의 할 일이다.
///
/// [auto] 면(로그인 직후 · 앱을 켠 직후 — `autoSpacePickerPath`) 고를 것이 분명할 때 곧장 넘긴다:
/// 마지막으로 들어간 스페이스, 없으면 하나뿐인 스페이스. 넘기는 동안은 목록 대신 뼈대를 보인다 —
/// 목록이 한 번 비쳤다 사라지면 무엇을 놓친 것처럼 보인다.
class SpacePickerScreen extends ConsumerStatefulWidget {
  const SpacePickerScreen({super.key, this.auto = false});

  final bool auto;

  @override
  ConsumerState<SpacePickerScreen> createState() => _SpacePickerScreenState();
}

class _SpacePickerScreenState extends ConsumerState<SpacePickerScreen> {
  /// 넘길지 아직 정하지 못했다. 한 번 정하면(넘기든 안 넘기든) 다시 따지지 않는다 —
  /// 목록이 다시 오더라도 사용자가 보고 있는 화면을 빼앗지 않는다.
  late bool _deciding = widget.auto;

  @override
  void initState() {
    super.initState();
    if (_deciding) _decide();
  }

  Future<void> _decide() async {
    final last = await ref.read(settingsStorageProvider).readLastSpace();
    final repository = ref.read(workspaceRepositoryProvider);
    final List<Space> list;
    try {
      // 서버에 먼저 묻는다 — 처음 켠 기기는 캐시가 비어 있어, 캐시만 보면 「하나뿐」을 놓친다.
      // 못 닿으면(오프라인) 캐시로 정한다.
      await repository.refreshSpaces();
      list = await repository.watchSpaces().first;
    } catch (_) {
      // 목록을 못 받으면 오류 화면이 할 일을 맡는다.
      if (mounted) setState(() => _deciding = false);
      return;
    }
    if (!mounted) return;
    final target = list.any((s) => s.id == last)
        ? last
        : (list.length == 1 ? list.single.id : null);
    if (target == null) {
      setState(() => _deciding = false);
      return;
    }
    context.go('/s/$target');
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final spaces = ref.watch(spacesProvider);

    return NxPage(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(NxSpacing.sp8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text('스페이스', style: nx.text.heading),
                ),
                const SizedBox(height: NxSpacing.sp2),
                Text('들어갈 곳을 고르세요', style: nx.text.secondary),
                const SizedBox(height: NxSpacing.sp8),
                Flexible(
                  child: _deciding
                      ? const NxSkeleton(lines: 3, lineHeight: 56)
                      : spaces.when(
                          // 자리를 지키는 뼈대(D10) — 회전 스피너를 두지 않는다.
                          loading: () =>
                              const NxSkeleton(lines: 3, lineHeight: 56),
                          error: (error, _) => _ErrorBlock(
                            error: error,
                            onRetry: () => ref.invalidate(spacesProvider),
                          ),
                          data: (list) => list.isEmpty
                              ? const _EmptyBlock()
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: list.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: NxSpacing.sp2),
                                  itemBuilder: (_, i) =>
                                      _SpaceTile(space: list[i]),
                                ),
                        ),
                ),
                const SizedBox(height: NxSpacing.sp8),
                Wrap(
                  spacing: NxSpacing.sp4,
                  runSpacing: NxSpacing.sp4,
                  children: [
                    NxButton(
                      label: '스페이스 만들기',
                      kind: NxButtonKind.secondary,
                      onPressed: () => showCreateSpaceDialog(context, ref),
                    ),
                    // 만들기와 같은 무게의 선택이라 같은 모양으로 둔다 — 하나만 옅은 바탕이면
                    // 둘 중 하나를 권하는 것처럼 읽힌다(2026-10-10 UI/UX 검토).
                    NxButton(
                      label: '초대 코드로 참여',
                      kind: NxButtonKind.secondary,
                      onPressed: () => showJoinSpaceDialog(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: NxSpacing.sp8),
                const _AccountLine(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 지금 계정과 로그아웃. 셸의 계정 메뉴 · 설정 창은 스페이스 안에서만 열린다 — **스페이스가
/// 하나도 없는 사람(방금 가입한 사람)은 여기 말고 나갈 길이 없다.**
class _AccountLine extends ConsumerWidget {
  const _AccountLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final auth = ref.watch(authControllerProvider);
    final email = auth is AuthSignedIn ? auth.user.email : null;
    return Row(
      children: [
        if (email != null)
          Expanded(
            child: Text(
              email,
              style: nx.text.secondary,
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          const Spacer(),
        NxButton(
          label: '로그아웃',
          kind: NxButtonKind.ghost,
          size: NxSize.sm,
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }
}

class _SpaceTile extends StatelessWidget {
  const _SpaceTile({required this.space});

  final Space space;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;

    return NxHoverSurface(
      onPressed: () => context.go('/s/${space.id}'),
      semanticLabel: space.name,
      padding: const EdgeInsets.all(NxSpacing.sp5),
      base: c.bgSurface,
      child: Row(
        children: [
          NexusAvatar(seed: space.id, label: space.name, squircle: true),
          const SizedBox(width: NxSpacing.sp5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(space.name, style: nx.text.strong),
                const SizedBox(height: NxSpacing.sp1),
                Text(
                  '/${space.slug} · ${roleLabel(space.role)}',
                  style: nx.text.meta,
                ),
              ],
            ),
          ),
          NxIcon(
            NxIcons.chevronRight,
            size: NxIconSize.sm,
            color: c.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock();

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NxSpacing.sp9),
      // 내용 높이만 차지한다 — 아니면 위 Flexible 안에서 늘어나 아래 버튼을 화면 끝으로 민다.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('속한 스페이스가 없습니다.', style: nx.text.body),
          const SizedBox(height: NxSpacing.sp2),
          Text('초대 코드로 참여하거나 새로 만드세요.', style: nx.text.secondary),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // 서버 문구를 그대로 쓰지 않는다. 종류만 보고 앱이 자기 문구를 쓴다.
    final text = messageForError(error);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NxSpacing.sp9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: NxTheme.of(context).text.body),
          const SizedBox(height: NxSpacing.sp5),
          NxButton(
            label: '다시 시도',
            kind: NxButtonKind.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
