import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// 브랜드 마크. **제안서(2026-08-31)가 갈라 둔 대로 두 벌을 쓴다.**
///
/// - [NexusLogo] — 3D CNC 티타늄 모놀리스. 워드마크가 함께 있는 «메인 심볼»
///   이라 브랜드를 처음 보여 주는 자리(로그인)에 쓴다.
/// - [NexusMarkTile] — 2D 플랫 'N'. 작게 놓이는 자리(스플래시 · 헤더)에 쓴다.
///   앱 아이콘 · 파비콘도 이 형태이고, 그쪽은 `design-system/logo/build_logo.py`
///   가 만든다.
///
/// **둘 다 검은 판 위에 놓는다.** 마크가 흰색과 은색이라 라이트 테마의 배경
/// (`#EFF0F1`)에 그대로 얹으면 워드마크가 통째로 사라진다. 제안서도 언제나
/// Space Black 위에 놓고 보여 준다 — 판은 배경이 아니라 마크의 일부다.
const _plateColor = Color(0xFF000000); // Space Black #000000

/// 판의 모서리 반경 비율. **`design-system/logo/build_logo.py` 의
/// `TILE_RADIUS_RATIO` 와 같은 값이어야 한다** — 앱 아이콘과 앱 안의 판이
/// 다른 모양이면 같은 물건으로 안 읽힌다. 눈대중으로 따로 적었다가 로고 판만
/// 9% 가 되어 아이콘(22.5%)보다 각져 있었다.
const _plateRadiusRatio = 0.225;

/// 메인 심볼. `width` 는 판이 아니라 **그림의 폭**이다.
///
/// 원본이 321×231 라스터라 그보다 크게 그리면 가장자리가 뭉갠다. 기본값을
/// 160 으로 둔 것은 2배 화면에서 320px 이 되어 원본과 거의 같기 때문이다.
class NexusLogo extends StatelessWidget {
  const NexusLogo({super.key, this.width = 160});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.10,
        vertical: width * 0.06,
      ),
      decoration: BoxDecoration(
        color: _plateColor,
        // 반경은 **판의 너비** 기준이다. 판은 그림 좌우로 10% 씩 더 넓다.
        borderRadius: BorderRadius.circular(width * 1.2 * _plateRadiusRatio),
      ),
      child: Image.asset(
        'assets/logo/nexus-monolith.png',
        width: width,
        // 원본 비율(321:231)을 그대로 둔다. 높이를 따로 주면 어느 쪽이
        // 기준인지 두 곳에서 정해진다.
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
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
/// **로고를 두고 스피너를 그 아래 작게 둔다** — 이 화면은 «켜지는 중» 을
/// 말하는 자리이지 «기다리는 중» 을 말하는 자리가 아니다. 서버가 꺼져 있으면
/// 여기 머무르므로(라우터의 리다이렉트 규칙) 빈 스피너 하나보다 낫다.
class NexusSplash extends StatelessWidget {
  const NexusSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NexusMarkTile(size: 88),
            const SizedBox(height: NexusSpacing.sp7),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
