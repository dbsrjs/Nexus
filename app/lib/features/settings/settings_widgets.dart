import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// 설정 섹션 한 장. 제목과 본문을 같은 폭 · 같은 간격으로 그린다.
///
/// **자기 폭을 모른다** — 두 단이든 한 단이든 받은 자리 안에서 최대 640px 로
/// 가운데가 아니라 왼쪽에 붙는다(디스코드). 폭 분기는 `SettingsFrame` 몫이다.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(NexusSpacing.sp8),
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: NexusSpacing.sp7),
                ...children,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 섹션 안의 소제목.
class SettingsLabel extends StatelessWidget {
  const SettingsLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: NexusSpacing.sp4),
        child: Text(text, style: Theme.of(context).textTheme.labelSmall),
      );
}

/// 저장 결과 한 줄. 성공과 실패를 색으로 가른다.
class SettingsNotice {
  const SettingsNotice.ok(this.text) : isError = false;
  const SettingsNotice.error(this.text) : isError = true;

  final String text;
  final bool isError;
}

class SettingsNoticeText extends StatelessWidget {
  const SettingsNoticeText(this.notice, {super.key});

  final SettingsNotice notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: NexusSpacing.sp5),
      child: Text(
        notice.text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: notice.isError ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
      ),
    );
  }
}
