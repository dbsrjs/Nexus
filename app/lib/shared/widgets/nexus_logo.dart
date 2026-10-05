import 'package:flutter/widgets.dart';

import '../../ui/theme.dart';

/// 브랜드 마크 타일 — 앱 아이콘 · 파비콘과 같은 'N'(«연결점», 2026-10-05).
/// 원본은 `design-system/logo/build_logo.py` 이고, 색 · 반경은 [NxBrand] 가 갖는다.
///
/// **타일은 검은 판째로 놓는다.** 마크가 흰 획이라 라이트 테마의 배경에 판 없이 얹으면
/// 사라진다 — 판은 배경이 아니라 마크의 일부다.
///
/// 로그인에 쓰던 3D 모놀리스 PNG 와 «타일 + 워드마크» 묶음(`NexusLogo`)은 걷었다.
/// 로그인은 이제 이 타일과 화면 제목(「Nexus에 로그인」)을 쓴다 — 이름이 두 번 나오지 않게.

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
        color: NxBrand.plate,
        borderRadius: BorderRadius.circular(size * NxBrand.plateRadiusRatio),
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
