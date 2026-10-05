import 'package:flutter/widgets.dart';

import '../../ui/theme.dart';

/// 브랜드 마크. **한 벌이다** — 앱 아이콘 · 파비콘 · 앱 안이 모두 같은 'N'
/// («연결점», 2026-10-05). 원본은 `design-system/logo/build_logo.py` 다.
///
/// - [NexusLogo] — 마크 타일 + 'Nexus' 워드마크. 브랜드를 처음 보여 주는
///   자리(로그인)에 쓴다.
/// - [NexusMarkTile] — 마크 타일만. 작게 놓이는 자리(스플래시)에 쓴다.
///
/// 로그인에 쓰던 3D 모놀리스 PNG 는 걷었다. 워드마크가 그림 안에 박힌
/// 321×231 라스터라 그림자에 'E' 가 묻혀 «N XUS» 로 읽혔고, 아이콘과 생김이
/// 달라 같은 브랜드로 읽히지 않았다. 워드마크는 이제 테마 글꼴의 글자다.
///
/// **타일은 검은 판째로 놓는다.** 마크가 흰 획이라 라이트 테마의 배경
/// (`#EFF0F1`)에 판 없이 얹으면 사라진다 — 판은 배경이 아니라 마크의 일부다.
const _plateColor = Color(0xFF000000); // Space Black #000000

/// 판의 모서리 반경 비율. **`design-system/logo/build_logo.py` 의
/// `TILE_RADIUS_RATIO` 와 같은 값이어야 한다** — 앱 아이콘과 앱 안의 판이
/// 다른 모양이면 같은 물건으로 안 읽힌다. 눈대중으로 따로 적었다가 로고 판만
/// 9% 가 되어 아이콘(22.5%)보다 각져 있었다.
const _plateRadiusRatio = 0.225;

/// 로그인의 브랜드 묶음 — 타일 위, 워드마크 아래.
///
/// 옛 모놀리스 판(그림 폭 132)은 라이트 테마에서 로그인 버튼보다 먼저 눈에
/// 들어왔다. 타일은 72 로 두어 아이콘 한 개의 무게에 그친다.
class NexusLogo extends StatelessWidget {
  const NexusLogo({super.key, this.size = 72});

  /// 타일 한 변. 워드마크 크기도 여기에 맞춘다.
  final double size;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return Semantics(
      label: 'Nexus',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NexusMarkTile(size: size),
          SizedBox(height: size * 0.22),
          Text(
            'Nexus',
            style: nx.text.heading.copyWith(
              fontSize: size * 0.39,
              height: 1.1,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 2D 플랫 마크를 얹은 타일. 앱 아이콘과 같은 모양이라, 런처에서 보던 것과
/// 앱 안에서 보는 것이 이어진다.
class NexusMarkTile extends StatelessWidget {
  const NexusMarkTile({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _plateColor,
        borderRadius: BorderRadius.circular(size * _plateRadiusRatio),
      ),
      // 마크 PNG 는 이미 여백을 품고 있어(1000 단위 중 464 만 그림) 여기서
      // 다시 padding 을 주지 않는다.
      child: Image.asset(
        'assets/logo/nexus-mark-256.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// 스플래시. 토큰을 복원하는 동안 잠깐 보이는 화면이다.
///
/// **도는 스피너를 두지 않는다**(15단계 D10) — 이 화면은 «켜지는 중» 을 말하는 자리다.
/// 서버가 꺼져 있으면 여기 머무르므로(라우터의 리다이렉트 규칙) 마크가 천천히 숨 쉬어
/// 멈춘 화면이 아님을 보인다.
class NexusSplash extends StatefulWidget {
  const NexusSplash({super.key});

  @override
  State<NexusSplash> createState() => _NexusSplashState();
}

class _NexusSplashState extends State<NexusSplash>
    with SingleTickerProviderStateMixin {
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: NxTheme.of(context).colors.bgBase,
      child: Center(
        child: Semantics(
          label: '불러오는 중',
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: .55).animate(
              CurvedAnimation(parent: _breath, curve: Curves.easeInOut),
            ),
            child: const NexusMarkTile(size: 88),
          ),
        ),
      ),
    );
  }
}
