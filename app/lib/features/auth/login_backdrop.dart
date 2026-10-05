import 'package:flutter/widgets.dart';

import '../../ui/ui.dart';

/// 로그인 화면의 배경 — 시안 A1 «연결망»(2026-10-05).
///
/// 빈 화면을 일러스트로 채우는 대신 **Nexus 가 실제로 모으는 것들의 조각**(대화 · AI 요약 ·
/// 이슈 · 커밋 · 파일)을 띄우고, 점선이 그 조각들을 가운데 카드로 잇는다. 새 마크의
/// «연결점» 을 화면 전체로 키운 것이다.
///
/// - **조각은 예시다.** 로그인 전이라 실제 데이터를 볼 권한이 없고, 기기에 남은 지난 계정의
///   캐시를 보이면 공용 PC 에서 대화가 새어 나간다. 그래서 문구를 [_fragments] 에 고정해
///   두었고, 커밋은 이 저장소의 진짜 커밋이다.
/// - **누를 수 없고 읽히지 않는다**(IgnorePointer · ExcludeSemantics). 「@민재」 같은 멘션이
///   진짜 알림으로 읽히면 안 된다.
/// - **자리가 모자라면 조각과 선을 그리지 않는다** — 점 격자만 남는다. 폼을 가리는 장식은
///   장식이 아니다.
class LoginBackdrop extends StatelessWidget {
  const LoginBackdrop({super.key, required this.child});

  /// 가운데 놓일 로그인 카드.
  final Widget child;

  /// 조각을 펼칠 수 있는 최소 크기 — **조각 배치에서 계산한다.** 숫자로 따로 적었다가
  /// 조각이 좌우 640 까지 나가는데 기준은 1100 이라, 창 폭 1100~1330 에서 조각이 잘렸다
  /// (2026-10-06 검토).
  static final Size _minWide = () {
    var reachX = 0.0, reachY = 0.0;
    for (final f in _fragments) {
      final x = f.anchor.dx < 0 ? -f.left : f.left + f.width;
      if (x > reachX) reachX = x;
      if (f.anchor.dy.abs() > reachY) reachY = f.anchor.dy.abs();
    }
    return Size(
      2 * (reachX + _margin),
      2 * (reachY + _halfHeightAllowance + _margin),
    );
  }();

  /// 조각 바깥 끝과 화면 가장자리 사이에 남길 여백.
  static const _margin = NxSpacing.sp8;

  /// 조각 높이의 절반으로 넉넉히 잡는 값. 가장 높은 조각(AI 요약 두 줄)이 OS 글자 배율
  /// 150% 에서 대략 130 이다.
  static const _halfHeightAllowance =
      NxSpacing.sp10 + NxSpacing.sp9 - NxSpacing.sp2;

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    return LayoutBuilder(
      builder: (context, box) {
        final wide =
            box.maxWidth >= _minWide.width && box.maxHeight >= _minWide.height;
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _DotGridPainter(c.decorDot)),
            ),
            if (wide) ...[
              Positioned.fill(
                child: CustomPaint(
                  painter: _WirePainter(c.decorWire, c.accent),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Stack(
                      children: [
                        for (final f in _fragments)
                          _Placed(fragment: f, child: _FragmentCard(f)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Positioned.fill(child: child),
          ],
        );
      },
    );
  }
}

// ── 배치 ─────────────────────────────────────────────────
// 모든 좌표는 **화면 가운데를 (0, 0) 으로 둔 논리 px** 이다. 시안이 1440×900 위에 그린
// 위치를 가운데 기준으로 옮겼다 — 창이 커져도 조각이 카드 주위에 모여 있게 한다.

class _Fragment {
  const _Fragment({
    required this.kind,
    required this.anchor,
    required this.width,
  });

  final _Kind kind;

  /// 점선이 출발하는 점 — **조각에서 카드를 향한 쪽 가장자리의 세로 가운데.** 조각은 이
  /// 점에 세로 가운데를 맞춰 놓인다. 위쪽 모서리 기준으로 놓고 점을 따로 적었더니, OS 글자
  /// 배율을 키워 조각이 높아지면 점선이 조각 가장자리에서 떨어졌다(2026-10-06 검토).
  final Offset anchor;
  final double width;

  /// 조각 왼쪽 끝의 x. 카드 왼쪽에 있으면 점이 오른쪽 가장자리, 오른쪽에 있으면 왼쪽 가장자리다.
  double get left => anchor.dx < 0 ? anchor.dx - width : anchor.dx;
}

enum _Kind { chat, ai, issue, commit, file }

const _fragments = <_Fragment>[
  _Fragment(kind: _Kind.chat, anchor: Offset(-290, -268), width: 290),
  _Fragment(kind: _Kind.ai, anchor: Offset(-340, 2), width: 300),
  _Fragment(kind: _Kind.issue, anchor: Offset(-290, 242), width: 270),
  _Fragment(kind: _Kind.commit, anchor: Offset(300, -253), width: 310),
  _Fragment(kind: _Kind.file, anchor: Offset(360, 142), width: 250),
];

class _Placed extends StatelessWidget {
  const _Placed({required this.fragment, required this.child});

  final _Fragment fragment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final center = box.biggest.center(Offset.zero);
        return Stack(
          children: [
            Positioned(
              left: center.dx + fragment.left,
              top: center.dy + fragment.anchor.dy,
              width: fragment.width,
              // 세로 가운데를 점선 출발점에 맞춘다 — 높이가 얼마든 점이 가장자리에 붙는다.
              child: FractionalTranslation(
                translation: const Offset(0, -.5),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── 그림 ─────────────────────────────────────────────────

/// 24px 간격의 점 격자. 바탕과 거의 같은 명도라 무늬로만 읽힌다.
class _DotGridPainter extends CustomPainter {
  _DotGridPainter(this.color);

  final Color color;
  static const _step = NxSpacing.sp8;
  static const _radius = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = _step / 2; y < size.height; y += _step) {
      for (var x = _step / 2; x < size.width; x += _step) {
        canvas.drawCircle(Offset(x, y), _radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}

/// 조각 → 화면 가운데로 휘어 들어가는 점선. 끝은 카드 아래로 숨는다.
class _WirePainter extends CustomPainter {
  _WirePainter(this.wire, this.dot);

  final Color wire;
  final Color dot;

  static const _dash = 4.0;
  static const _gap = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final line = Paint()
      ..color = wire
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final node = Paint()..color = dot;

    for (final f in _fragments) {
      final from = center + f.anchor;
      // 조각 쪽에서는 수평에 가깝게 나가다가 가운데로 꺾여 들어간다.
      final control = Offset(
        center.dx + f.anchor.dx * .35,
        center.dy + f.anchor.dy * .9,
      );
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(control.dx, control.dy, center.dx, center.dy);
      _drawDashed(canvas, path, line);
      canvas.drawCircle(from, 4, node);
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
        d += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_WirePainter old) => old.wire != wire || old.dot != dot;
}

// ── 조각 ─────────────────────────────────────────────────

class _FragmentCard extends StatelessWidget {
  const _FragmentCard(this.fragment);

  final _Fragment fragment;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NxSpacing.sp6,
        vertical: NxSpacing.sp5,
      ),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(NxRadius.md),
        border: Border.all(color: c.divider),
      ),
      child: switch (fragment.kind) {
        _Kind.chat => _chat(nx),
        _Kind.ai => _ai(nx),
        _Kind.issue => _issue(nx),
        _Kind.commit => _commit(nx),
        _Kind.file => _file(nx),
      },
    );
  }

  Widget _avatar(NxThemeData nx, String initial, int slot, double size) =>
      Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: nx.colors.avatars[slot],
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: nx.text.xs.copyWith(
            color: nx.colors.onBright,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _mention(NxThemeData nx, String name) => Container(
    padding: const EdgeInsets.symmetric(horizontal: NxSpacing.sp2),
    decoration: BoxDecoration(
      color: nx.colors.accentSubtle,
      borderRadius: BorderRadius.circular(NxRadius.sm),
    ),
    child: Text(
      name,
      style: nx.text.sm.copyWith(
        color: nx.colors.accent,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _chat(NxThemeData nx) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _avatar(nx, '서', 2, NxSpacing.sp9),
      const SizedBox(width: NxSpacing.inset),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '서윤',
                  style: nx.text.sm.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: NxSpacing.sp4),
                Text('10:42', style: nx.text.mono),
              ],
            ),
            const SizedBox(height: NxSpacing.sp1),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: NxSpacing.sp2,
              children: [
                _mention(nx, '@민재'),
                Text('배포 브랜치 확인 부탁해요', style: nx.text.sm),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _ai(NxThemeData nx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          NxIcon(NxIcons.ai, size: NxIconSize.sm, color: nx.colors.accent),
          const SizedBox(width: NxSpacing.sp4),
          Text(
            'AI · 채널 요약',
            style: nx.text.xs.copyWith(
              color: nx.colors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: NxSpacing.sp3),
      Text(
        '#backend 어제 대화 — 웹훅 재시도를 1분 간격 3회로 정했고, '
        '남은 일은 알림 읽음 동기화입니다.',
        style: nx.text.secondary.copyWith(height: 1.55),
      ),
    ],
  );

  Widget _chip(NxThemeData nx, String label) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: NxSpacing.sp3,
      vertical: NxSpacing.sp1,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(NxRadius.sm),
      border: Border.all(color: nx.colors.divider),
    ),
    child: Text(label, style: nx.text.meta.copyWith(fontSize: NxFontSize.xs2)),
  );

  Widget _issue(NxThemeData nx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text('NX-142', style: nx.text.mono.copyWith(fontSize: NxFontSize.xs)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: NxSpacing.sp4,
              vertical: NxSpacing.sp1,
            ),
            decoration: BoxDecoration(
              color: nx.colors.accentSubtle,
              borderRadius: BorderRadius.circular(NxRadius.full),
            ),
            child: Text(
              '진행 중',
              style: nx.text.xs2.copyWith(
                color: nx.colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: NxSpacing.sp4),
      Text(
        '알림함 읽음 동기화',
        style: nx.text.sm.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: NxSpacing.sp4),
      Row(
        children: [
          _chip(nx, '버그'),
          const SizedBox(width: NxSpacing.sp3),
          _chip(nx, '스프린트 7'),
          const Spacer(),
          _avatar(nx, '민', 6, NxSpacing.sp7),
        ],
      ),
    ],
  );

  Widget _commit(NxThemeData nx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text('nexus / main', style: nx.text.mono),
          const Spacer(),
          Text('push', style: nx.text.mono),
        ],
      ),
      const SizedBox(height: NxSpacing.sp4),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '51eb8ab ',
              style: nx.text.mono.copyWith(
                fontSize: NxFontSize.xs,
                color: nx.colors.accent,
              ),
            ),
            TextSpan(text: 'feat: 브랜드 마크를 시안 C «연결점» 으로 교체', style: nx.text.sm),
          ],
        ),
      ),
      const SizedBox(height: NxSpacing.sp4),
      Text.rich(
        TextSpan(
          style: nx.text.mono,
          children: [
            TextSpan(
              text: '+92 ',
              style: TextStyle(color: nx.colors.success),
            ),
            TextSpan(
              text: '−85 ',
              style: TextStyle(color: nx.colors.danger),
            ),
            const TextSpan(text: '· 19 files'),
          ],
        ),
      ),
    ],
  );

  Widget _file(NxThemeData nx) => Row(
    children: [
      Container(
        width: NxSpacing.sp9 + NxSpacing.sp2,
        height: NxSpacing.sp10 - NxSpacing.sp2,
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: NxSpacing.sp3),
        decoration: BoxDecoration(
          color: nx.colors.bgElevated,
          borderRadius: BorderRadius.circular(NxRadius.inner),
          border: Border.all(color: nx.colors.divider),
        ),
        child: Text(
          'PDF',
          style: nx.text.mono.copyWith(color: nx.colors.accent),
        ),
      ),
      const SizedBox(width: NxSpacing.sp5),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'release-notes.pdf',
              style: nx.text.sm.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: NxSpacing.sp1),
            Text('2.4 MB · #release', style: nx.text.mono),
          ],
        ),
      ),
    ],
  );
}
