import 'package:flutter/widgets.dart';

import '../../ui/ui.dart';

/// 파일 종류 표지 — 확장자를 모노 글자로 담은 작은 판(`PDF` · `ZIP`).
///
/// **아이콘 대신 글자다**(15단계 D5). 종류마다 그림을 두면 아이콘 수만 늘고, 확장자가
/// 그 자체로 가장 정확한 이름이다. 모르면(확장자 없음) `FILE`.
class FileKindBadge extends StatelessWidget {
  const FileKindBadge({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  static String extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return 'FILE';
    final ext = name.substring(dot + 1).toUpperCase();
    return ext.length > 4 ? ext.substring(0, 4) : ext;
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: BorderRadius.circular(NxRadius.sm),
      ),
      child: Text(
        extensionOf(name),
        style: nx.text.mono.copyWith(
          fontSize: 10, // 토큰 밖: 파일 아이콘 안의 확장자 — 아이콘 크기에 묶인 축소 글자
          fontWeight: FontWeight.w600,
          color: c.textSecondary,
        ),
      ),
    );
  }
}
