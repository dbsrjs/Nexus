import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/invite.dart';
import '../../domain/models/space.dart';
import '../../ui/ui.dart';
import '../settings/settings_widgets.dart';
import '../space/members_controller.dart';
import 'space_settings_controller.dart';

/// 스페이스 설정 「초대」(16단계 설계 D8~D10). admin+ 에게만 보인다.
///
/// 딥링크는 «마지막» 단계라 **코드를 건넨다.** 받는 사람은 스페이스 화면의
/// 「초대 코드로 참여」에 붙여넣는다.
class InvitesSection extends ConsumerStatefulWidget {
  const InvitesSection({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<InvitesSection> createState() => _InvitesSectionState();
}

class _InvitesSectionState extends ConsumerState<InvitesSection> {
  // 설계 D10 — 자주 쓰는 값만 고른다. 숫자 입력칸은 두지 않는다.
  SpaceRole _role = SpaceRole.member;
  int? _hours = 24 * 7;
  int? _uses;

  bool _busy = false;
  String? _error;
  Invite? _created;

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final invite = await ref.read(invitesApiProvider).create(
            widget.spaceId,
            role: _role,
            expiresInHours: _hours,
            maxUses: _uses,
          );
      ref.invalidate(invitesProvider(widget.spaceId));
      if (mounted) setState(() => _created = invite);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = messageFor(e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invites = ref.watch(invitesProvider(widget.spaceId));
    final created = _created;

    return SettingsPage(
      title: '초대',
      children: [
        const SettingsLabel('역할'),
        NxSegmented<SpaceRole>(
          label: '역할',
          expand: false,
          value: _role,
          onChanged: (v) => setState(() => _role = v),
          segments: const [
            (SpaceRole.guest, '손님'),
            (SpaceRole.member, '멤버'),
            (SpaceRole.admin, '관리자'),
          ],
        ),
        const SizedBox(height: NxSpacing.sp7),
        const SettingsLabel('유효 기간'),
        NxSegmented<int?>(
          label: '유효 기간',
          expand: false,
          value: _hours,
          onChanged: (v) => setState(() => _hours = v),
          segments: const [(24, '1일'), (24 * 7, '7일'), (null, '무기한')],
        ),
        const SizedBox(height: NxSpacing.sp7),
        const SettingsLabel('사용 횟수'),
        NxSegmented<int?>(
          label: '사용 횟수',
          expand: false,
          value: _uses,
          onChanged: (v) => setState(() => _uses = v),
          segments: const [(1, '1회'), (10, '10회'), (null, '무제한')],
        ),
        const SizedBox(height: NxSpacing.sp7),
        Align(
          alignment: Alignment.centerLeft,
          child: NxButton(
            label: '초대 코드 만들기',
            loading: _busy,
            onPressed: _busy ? null : _create,
          ),
        ),
        if (_error != null) SettingsError(_error!),
        if (created != null) ...[
          const SizedBox(height: NxSpacing.sp7),
          _CodeBox(code: created.code),
        ],
        const SettingsGap(),
        const SettingsLabel('쓸 수 있는 초대'),
        if (invites.hasError)
          SettingsError(errorMessageOf(invites.error))
        else if (!invites.hasValue)
          const NxSkeleton(lines: 2, lineHeight: 48)
        else if (invites.value!.isEmpty)
          Text('쓸 수 있는 초대가 없습니다.', style: NxTheme.of(context).text.secondary)
        else
          for (final invite in invites.value!)
            _InviteRow(spaceId: widget.spaceId, invite: invite),
      ],
    );
  }
}

/// 방금 만든 코드 — 크게 보이고 복사한다.
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    return Container(
      padding: const EdgeInsets.all(NxSpacing.sp6),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(NxRadius.md),
        border: Border.all(color: c.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  style: nx.text.mono.copyWith(fontSize: 20, color: c.textPrimary),
                ),
              ),
              NxButton(
                label: '복사',
                kind: NxButtonKind.secondary,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    NxToast.show(context, '복사했습니다', kind: NxToastKind.success);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: NxSpacing.sp4),
          Text(
            '받는 사람은 스페이스 화면의 「초대 코드로 참여」에 붙여넣으면 됩니다.',
            style: nx.text.meta,
          ),
        ],
      ),
    );
  }
}

class _InviteRow extends ConsumerWidget {
  const _InviteRow({required this.spaceId, required this.invite});

  final String spaceId;
  final Invite invite;

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    final ok = await NxDialog.confirm(
      context,
      title: '이 초대를 취소할까요?',
      body: '아직 쓰지 않은 사람은 이 코드로 들어올 수 없게 됩니다.',
      confirmLabel: '초대 취소',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(invitesApiProvider).revoke(spaceId, invite.id);
      ref.invalidate(invitesProvider(spaceId));
    } on ApiException catch (e) {
      if (context.mounted) {
        NxToast.show(context, messageFor(e.failure), kind: NxToastKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: NxRow(
        title: invite.code,
        titleStyle: NxTheme.of(context).text.mono,
        subtitle: inviteSummary(invite),
        trailing: NxButton(
          label: '취소',
          kind: NxButtonKind.ghost,
          size: NxSize.sm,
          onPressed: () => _revoke(context, ref),
        ),
      ),
    );
  }
}

/// 초대 한 줄의 설명 — 「멤버 · 10월 11일까지 · 3회 남음 · 가영」.
String inviteSummary(Invite invite) {
  final expires = invite.expiresAt?.toLocal();
  final maxUses = invite.maxUses;
  return [
    roleLabel(invite.role),
    expires == null ? '무기한' : '${expires.month}월 ${expires.day}일까지',
    maxUses == null ? '횟수 무제한' : '${maxUses - invite.useCount}회 남음',
    ?invite.createdByName,
  ].join(' · ');
}
