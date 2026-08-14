import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// 이름의 첫 글자를 담은 원형 아바타.
///
/// 색은 `hash(seed) % 8` 로 고른다 — **같은 사람·같은 스페이스는 어디서든 같은
/// 색**이라야 눈이 익는다 (design-system/tokens.css 의 아바타 8색 규칙).
/// 그래서 seed 는 이름이 아니라 **id** 를 넘긴다. 이름은 바뀔 수 있다.
class NexusAvatar extends StatelessWidget {
  const NexusAvatar({
    super.key,
    required this.seed,
    required this.label,
    this.size = 40,
    this.selected = false,
    this.squircle = false,
  });

  /// 색을 정하는 값. 사용자 id · 스페이스 id 처럼 변하지 않는 것을 넘긴다.
  final String seed;

  /// 첫 글자를 뽑을 문자열.
  final String label;

  final double size;

  /// 선택 상태 — 테두리로 표시한다.
  final bool selected;

  /// 스페이스는 사각에 가깝게, 사람은 원형으로 구분한다.
  final bool squircle;

  @override
  Widget build(BuildContext context) {
    final color = NexusColors.avatars[seed.hashCode.abs() % NexusColors.avatars.length];
    final initial = label.characters.isEmpty ? '?' : label.characters.first;
    final radius = squircle ? NexusRadius.md * 2 : size;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: selected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          // 아바타 8색은 명도 66% 고정이라 어두운 글자가 항상 읽힌다.
          color: NexusColors.bgBaseDark,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
