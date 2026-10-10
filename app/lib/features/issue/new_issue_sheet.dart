import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/issue.dart';
import '../../domain/models/message.dart';
import '../../domain/models/sprint.dart';
import '../../ui/ui.dart';
import '../space/members_controller.dart';
import 'board_controller.dart';
import 'sprint_controller.dart';

/// 새 이슈를 만드는 패널(바텀시트의 자리, 15단계 D8).
///
/// 만들면 **그 컬럼 맨 위**에 놓인다(서버가 정한다). 방금 만든 것이 보이지
/// 않으면 만든 사람은 실패했다고 믿는다.
/// `fromMessage` 를 주면 **대화 → 이슈**다. 제목을 원문에서 미리 채우고
/// 원문 링크를 함께 보낸다 — 이슈에서 그 대화로 돌아올 수 있어야 한다.
///
/// AI 이슈 초안(13-2)은 `initialTitle` · `initialDescription` 으로 채우고
/// 원문은 id(`originMessageId`)로만 넘긴다 — 메시지 객체를 들고 있지 않다.
Future<void> showNewIssueSheet(
  BuildContext context, {
  Message? fromMessage,
  String? originMessageId,
  String? initialTitle,
  String? initialDescription,
}) => NxDialog.panel<void>(
  context,
  title: (fromMessage?.id ?? originMessageId) == null ? '새 이슈' : '대화에서 이슈 만들기',
  width: 520,
  builder: (_) => _NewIssueSheet(
    fromMessage: fromMessage,
    originMessageId: originMessageId,
    initialTitle: initialTitle,
    initialDescription: initialDescription,
  ),
);

class _NewIssueSheet extends ConsumerStatefulWidget {
  const _NewIssueSheet({
    this.fromMessage,
    this.originMessageId,
    this.initialTitle,
    this.initialDescription,
  });

  final Message? fromMessage;
  final String? originMessageId;
  final String? initialTitle;
  final String? initialDescription;

  String? get _originId => fromMessage?.id ?? originMessageId;

  @override
  ConsumerState<_NewIssueSheet> createState() => _NewIssueSheetState();
}

class _NewIssueSheetState extends ConsumerState<_NewIssueSheet> {
  late final _title = TextEditingController(
    text: widget.initialTitle ?? _titleFromMessage(),
  );
  late final _description = TextEditingController(
    text: widget.initialDescription ?? '',
  );

  /// 원문의 첫 줄을 제목으로 쓴다. 긴 글을 통째로 제목에 넣으면 카드가
  /// 읽히지 않으므로 자른다 — 전문은 원문 링크를 눌러 보면 된다.
  String _titleFromMessage() {
    final body = widget.fromMessage?.body.trim();
    if (body == null || body.isEmpty) return '';
    final firstLine = body.split('\n').first.trim();
    return firstLine.length <= 80
        ? firstLine
        : '${firstLine.substring(0, 79)}…';
  }

  IssueStatus _status = IssueStatus.backlog;
  IssuePriority _priority = IssuePriority.mid;

  /// 담당자 — 기본은 없음. 만드는 사람에게 자동으로 붙이지 않는다: 일을 적어 두는 사람과
  /// 맡는 사람이 다른 경우가 흔하고, 잘못 붙은 담당은 「누가 하고 있다」로 읽힌다.
  String? _assigneeId;

  /// 사람이 고른 스프린트. 고르기 전에는 [_sprintId] 가 기본값을 낸다.
  String? _sprintChoice;
  bool _sprintChosen = false;

  /// 스프린트 — **보드가 「이번 스프린트」를 보고 있으면 그 스프린트로 시작한다.** 비워 두면
  /// 방금 만든 이슈가 지금 보이는 보드에서 빠져, 만든 사람은 실패했다고 믿는다(위 문서의
  /// 「그 컬럼 맨 위」와 같은 이유). 다른 보기에서는 백로그(없음)로 시작한다.
  ///
  /// 기본값을 처음 한 번만 정해 두지 않는다 — 스프린트 목록이 패널보다 늦게 오면 그때
  /// 「도는 스프린트 없음」으로 굳어 버린다. 고르기 전까지는 매번 지금 값으로 계산한다.
  String? get _sprintId {
    if (_sprintChosen) return _sprintChoice;
    if (!ref.read(sprintsEnabledProvider)) return null;
    return ref.read(boardScopeProvider) == BoardScope.activeSprint
        ? ref.read(activeSprintProvider)?.id
        : null;
  }

  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty || _sending) return;

    setState(() => _sending = true);
    final navigator = Navigator.of(context);

    final ok = await ref
        .read(boardActionsProvider)
        .create(
          title: title,
          description: _description.text.trim(),
          status: _status,
          priority: _priority,
          assigneeId: _assigneeId,
          // 스프린트를 끈 스페이스에서는 칸이 안 보이므로 보내지도 않는다.
          sprintId: ref.read(sprintsEnabledProvider) ? _sprintId : null,
          originMessageId: widget._originId,
        );

    if (!mounted) return;
    if (ok) {
      navigator.pop();
      return;
    }
    setState(() => _sending = false);
    // 큐에 넣지 않으므로 오프라인에서는 만들 수 없다. 그 사실을 그대로 말한다.
    NxToast.show(context, '만들지 못했습니다. 연결을 확인해 주세요.', kind: NxToastKind.error);
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final members = ref.watch(spaceMembersProvider).value ?? const [];
    final sprintsOn = ref.watch(sprintsEnabledProvider);
    final openSprints = sprintsOn
        ? (ref.watch(sprintListProvider).value ?? const <Sprint>[])
              .where((s) => s.state != SprintState.closed)
              .toList(growable: false)
        : const <Sprint>[];
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: NxSpacing.sp3),
      child: Text(
        text,
        style: nx.text.xs.copyWith(
          fontWeight: FontWeight.w600,
          color: nx.colors.textSecondary,
        ),
      ),
    );

    return SingleChildScrollView(
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
            label: '제목',
            controller: _title,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: NxSpacing.sp6),
          NxField(
            label: '설명 (선택)',
            controller: _description,
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: NxSpacing.sp6),
          // 「컬럼」은 보드의 생김새를 가리키는 말이다 — 고르는 것은 이슈의 상태다.
          label('상태'),
          NxSegmented<IssueStatus>(
            label: '상태',
            value: _status,
            segments: [
              for (final s in IssueStatus.values) (s, issueStatusLabel(s)),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: NxSpacing.sp6),
          label('우선순위'),
          NxSegmented<IssuePriority>(
            label: '우선순위',
            value: _priority,
            segments: [
              for (final p in IssuePriority.values) (p, issuePriorityLabel(p)),
            ],
            onChanged: (v) => setState(() => _priority = v),
          ),
          const SizedBox(height: NxSpacing.sp6),
          label('담당자'),
          _Picker(
            semanticLabel: '담당자',
            value: _assigneeId,
            options: [
              (null, '없음'),
              // 실패하면 빈 목록이다(멘션 자동완성과 같은 provider) — 「없음」만 남을 뿐
              // 이슈는 만들 수 있다.
              for (final m in members) (m.userId, m.displayName),
            ],
            onChanged: (v) => setState(() => _assigneeId = v),
          ),
          if (sprintsOn) ...[
            const SizedBox(height: NxSpacing.sp6),
            label('스프린트'),
            _Picker(
              semanticLabel: '스프린트',
              value: _sprintId,
              options: [
                (null, '백로그 (스프린트 없음)'),
                // 닫힌 스프린트는 고를 수 없다 — 지난 번다운이 뒤늦게 흔들린다
                // (이슈 상세의 계획 줄과 같은 규칙).
                for (final sprint in openSprints)
                  (
                    sprint.id,
                    '${sprint.name} · ${sprintStateLabel(sprint.state)}',
                  ),
              ],
              onChanged: (v) => setState(() {
                _sprintChosen = true;
                _sprintChoice = v;
              }),
            ),
          ],
          const SizedBox(height: NxSpacing.sp7),
          Align(
            alignment: Alignment.centerRight,
            child: NxButton(
              label: '만들기',
              loading: _sending,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

/// 패널 폭을 채우는 [NxSelect]. 패널은 화면 폭에 따라 좁아지므로 폭을 박지 않고 받는다.
class _Picker extends StatelessWidget {
  const _Picker({
    required this.semanticLabel,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String semanticLabel;
  final String? value;
  final List<(String?, String)> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) => NxSelect<String?>(
          width: constraints.maxWidth,
          value: value,
          options: options,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
