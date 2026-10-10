import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/josa.dart';
import '../../data/api/api_failure.dart';
import '../../ui/ui.dart';
import 'invite_code.dart';
import 'members_controller.dart';
import 'space_controller.dart';
import 'space_dialogs.dart';

/// `/invite/:code` — 초대 링크로 들어온 자리(«마지막» 딥링크).
///
/// **누르자마자 참여시키지 않는다.** 링크는 메신저에서 미리보기로 열리기도 하고, 받은 사람이
/// 어느 계정으로 로그인돼 있는지 확인할 틈이 있어야 한다 — 한 번 더 누르게 한다.
/// 로그인이 안 돼 있으면 라우터가 로그인을 거쳐 이 주소로 되돌려 준다(auth_redirect.dart).
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key, required this.rawCode});

  /// 주소에 실려 온 그대로. 대소문자 · 꼬리 문자가 섞여도 붙여넣기와 같은 규칙으로 읽는다.
  final String rawCode;

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  bool _busy = false;
  String? _error;

  String? get _code => parseInviteCode(widget.rawCode);

  Future<void> _join() async {
    final code = _code;
    if (code == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await ref.read(invitesApiProvider).accept(code);
      await ref.read(workspaceRepositoryProvider).refreshSpaces();
      if (mounted) context.go('/s/$id');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = joinMessageFor(e.failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final code = _code;

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
                  child: Text('스페이스 초대', style: nx.text.heading),
                ),
                const SizedBox(height: NxSpacing.sp2),
                Text(
                  code == null
                      ? '초대 링크가 올바르지 않습니다. 받은 링크를 다시 확인하세요.'
                      : '초대 코드 ${withRo(code)} 스페이스에 참여합니다.',
                  style: nx.text.secondary,
                ),
                if (_error != null) ...[
                  const SizedBox(height: NxSpacing.sp4),
                  Text(
                    _error!,
                    style: nx.text.secondary.copyWith(color: nx.colors.danger),
                  ),
                ],
                const SizedBox(height: NxSpacing.sp8),
                Wrap(
                  spacing: NxSpacing.sp4,
                  runSpacing: NxSpacing.sp4,
                  children: [
                    if (code != null)
                      NxButton(label: '참여', loading: _busy, onPressed: _join),
                    NxButton(
                      label: '스페이스 목록으로',
                      kind: NxButtonKind.ghost,
                      onPressed: () => context.go('/spaces'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
