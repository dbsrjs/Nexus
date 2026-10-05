import 'package:flutter/widgets.dart';

/// Nexus 자체 테마(15단계 설계 D4). **Material 의 `ThemeData` 를 쓰지 않는다.**
///
/// 값은 `design-system/tokens.css` 와 1:1 이다 — 토큰 이름을 바꾸지 않는다
/// (`--bg-surface` → `bgSurface`). 갈라지면 디자인 문서와 대조할 수 없다.
@immutable
class NxColors {
  const NxColors._({
    required this.bgBase,
    required this.bgSurface,
    required this.bgElevated,
    required this.divider,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentSubtle,
    required this.accentPress,
  });

  final Color bgBase;
  final Color bgSurface;
  final Color bgElevated;

  /// 구조 구분선 — 거의 보이지 않아야 한다(≈1.3:1).
  final Color divider;

  /// 비활성 아이콘 · 입력 테두리 · 칩 — 읽혀야 한다(≈3:1).
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;

  final Color accent;
  final Color accentSubtle;
  final Color accentPress;

  // ── 시맨틱 · 아바타는 밝기와 무관하다 ──
  Color get success => const Color(0xFF74B48F);
  Color get warning => const Color(0xFFD3B069);
  Color get danger => const Color(0xFFD47D7D);
  Color get merged => const Color(0xFFA18ECC);

  /// 액센트 위의 글자 — **바탕색**이다(옛 ThemeData 의 onPrimary 와 같다). 다크의 액센트는
  /// 밝고(#77AECF) 라이트의 액센트는 어두워(#326C8F) 고정색 하나로는 한쪽이 읽히지 않는다 —
  /// 라이트에서 어두운 글자를 얹었다가 갤러리에서 놓치고 설정 화면 캡처에서 찾았다.
  Color get onAccent => bgBase;

  /// 투명. **화면에 `Color(0x00000000)` 을 쓰지 않고 이것을 쓴다** — 호버 전 배경 ·
  /// 선택 안 된 테두리처럼 «없음» 을 뜻하는 자리. 숫자로 박으면 토큰 검사가 잡는다.
  static const transparent = Color(0x00000000);

  // ── 장식(로그인 같은 빈 화면의 배경) ──

  /// 점 격자의 점. 본문 글자색을 10% 로 — 바탕과 거의 같은 명도라 «무늬» 로만 읽힌다.
  Color get decorDot => textPrimary.withValues(alpha: .10);

  /// 조각을 잇는 점선. 액센트를 38% 로 — 선이 폼보다 먼저 눈에 들어오면 안 된다.
  Color get decorWire => accent.withValues(alpha: .38);

  /// 밝기와 무관하게 밝은 고정색(위험 · 아바타 8색) 위의 글자.
  Color get onBright => const Color(0xFF121314);

  /// 다이얼로그 · 동작 카드 뒤의 막. 오버레이만 예외로 쓴다(디자인 시스템 §4).
  Color get scrim => const Color(0xB8121314);

  /// 8색 전부 채도 28% · 명도 66%. 배정은 `hash(id) % 8`.
  List<Color> get avatars => const [
    Color(0xFF90A8C1),
    Color(0xFF9C90C1),
    Color(0xFFC190C1),
    Color(0xFFC1909C),
    Color(0xFFC1A890),
    Color(0xFFB4C190),
    Color(0xFF90C1A0),
    Color(0xFF90C1C1),
  ];

  static const dark = NxColors._(
    bgBase: Color(0xFF121314),
    bgSurface: Color(0xFF1C1D1F),
    bgElevated: Color(0xFF282A2C),
    divider: Color(0x1ADDE6ED),
    borderStrong: Color(0xFF63676B),
    textPrimary: Color(0xFFDDE6ED),
    textSecondary: Color(0xFF9DA0A4),
    accent: Color(0xFF77AECF),
    accentSubtle: Color(0x2177AECF),
    accentPress: Color(0xFF5197C2),
  );

  static const light = NxColors._(
    bgBase: Color(0xFFEFF0F1),
    bgSurface: Color(0xFFF7F8F8),
    bgElevated: Color(0xFFFFFFFF),
    divider: Color(0x1C121314),
    borderStrong: Color(0xFFA8ABAE),
    textPrimary: Color(0xFF27374D),
    textSecondary: Color(0xFF5E6165),
    accent: Color(0xFF326C8F),
    accentSubtle: Color(0x17326C8F),
    accentPress: Color(0xFF285571),
  );
}

/// 브랜드 마크의 색. **테마를 따르지 않는다** — 마크는 OS 런처 · 브라우저 탭에서와 같은
/// 물건이어야 해서 앱이 다크든 라이트든 같은 색이다. 원본은
/// `design-system/logo/build_logo.py` 이고, 값이 갈라지면 아이콘과 앱 안 마크가 달라진다.
class NxBrand {
  const NxBrand._();

  /// 타일 바탕 — Space Black.
  static const plate = Color(0xFF000000);

  /// 'N' 두 획.
  static const mark = Color(0xFFFFFFFF);

  /// 연결점(노드). 다크 테마의 `accent` 와 같은 값이다.
  static const node = Color(0xFF77AECF);

  /// 타일 모서리 반경 ÷ 타일 한 변. `build_logo.py` 의 `TILE_RADIUS_RATIO`.
  static const plateRadiusRatio = 0.225;
}

class NxSpacing {
  const NxSpacing._();

  static const double sp1 = 2;
  static const double sp2 = 4;
  static const double sp3 = 6;
  static const double sp4 = 8;
  static const double sp5 = 12;
  static const double sp6 = 16;
  static const double sp7 = 20;
  static const double sp8 = 24;
  static const double sp9 = 32;
  static const double sp10 = 48;

  /// **목록 줄 · 메뉴 항목의 좌우 안쪽**과 줄 머리 아이콘 ↔ 글자 사이. 4px 격자 밖의
  /// 유일한 간격이다 — 8 이면 줄 머리 아이콘이 가장자리에 붙어 보이고 12 면 목록이
  /// 들떠 보였다. 15단계 이전부터 40곳 가까이 숫자로 박혀 있던 값을 이름으로 올렸다.
  static const double inset = 10;
}

class NxRadius {
  const NxRadius._();

  static const double sm = 4;

  /// **패널 안의 항목** — 메뉴 항목 · 토스트 버튼 · 선택 손잡이. 바깥 판(`md`)보다
  /// 한 단 작게 두어 안쪽 모서리가 바깥 모서리와 평행해 보이게 한다.
  static const double inner = 6;

  static const double md = 8;

  /// 동작 카드 · 모바일 메뉴처럼 화면 위에 뜨는 것. 캔버스 결정(15단계).
  static const double lg = 12;
  static const double full = 9999;
}

class NxMotion {
  const NxMotion._();

  static const micro = Duration(milliseconds: 120);
  static const panel = Duration(milliseconds: 180);
  static const ease = Cubic(0, 0, 0.2, 1);
}

/// 글자 크기. **화면에서 `fontSize:` 에 숫자를 쓰지 않고 이것을 쓴다.**
/// `tokens.css` 의 `--text-*` 와 1:1 이다.
class NxFontSize {
  const NxFontSize._();

  static const double xs2 = 11;
  static const double xs = 12;
  static const double sm = 13;
  static const double base = 14;

  /// 읽는 본문 · 머리 줄 제목.
  static const double body = 15;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
}

const _font = 'Pretendard';
const _fallback = <String>['Segoe UI', 'Noto Sans KR'];
const _mono = 'JetBrains Mono';
const _monoFallback = <String>['Consolas', 'monospace'];

/// 글자 스타일. 크기 이름은 토큰 그대로(`--text-sm` → `sm`), 쓰임새 이름은 그 위의 조합이다.
@immutable
class NxText {
  const NxText._(this._c);

  final NxColors _c;

  TextStyle _ui(double size, {FontWeight? weight, Color? color}) => TextStyle(
    fontFamily: _font,
    fontFamilyFallback: _fallback,
    fontSize: size,
    height: 1.3,
    fontWeight: weight ?? FontWeight.w400,
    color: color ?? _c.textPrimary,
    decoration: TextDecoration.none,
  );

  // ── 크기(토큰) ──
  TextStyle get xs2 => _ui(NxFontSize.xs2);
  TextStyle get xs => _ui(NxFontSize.xs);
  TextStyle get sm => _ui(NxFontSize.sm);
  TextStyle get base => _ui(NxFontSize.base);
  TextStyle get md => _ui(NxFontSize.md);
  TextStyle get lg => _ui(NxFontSize.lg);
  TextStyle get xl => _ui(NxFontSize.xl);

  /// **읽는 본문** — 메시지 · 이슈 본문 · 댓글. 15px · 행간 1.6.
  TextStyle get body => _ui(NxFontSize.body).copyWith(height: 1.6);

  // ── 쓰임새 ──
  TextStyle get heading => _ui(NxFontSize.lg, weight: FontWeight.w700);
  TextStyle get title => _ui(NxFontSize.md, weight: FontWeight.w600);

  /// **머리 줄 제목** — 채널 이름 · 스페이스 이름 · 화면 머리 줄. 15px · 700.
  /// 화면마다 `title.copyWith(fontSize: 15, …)` 를 따로 쓰다가 굵기가 600 과 700 으로
  /// 갈라져 있었다.
  TextStyle get header => _ui(NxFontSize.body, weight: FontWeight.w700);
  TextStyle get strong => _ui(NxFontSize.base, weight: FontWeight.w600);
  TextStyle get secondary => _ui(NxFontSize.sm, color: _c.textSecondary);
  TextStyle get meta => _ui(NxFontSize.xs, color: _c.textSecondary);

  /// 섹션 머리(「작업」 · 「일반」). 대문자가 없는 한글이라 자간만 조금 연다.
  TextStyle get label => _ui(
    NxFontSize.xs2,
    weight: FontWeight.w600,
    color: _c.borderStrong,
  ).copyWith(letterSpacing: 0.6);

  /// 타임스탬프 · 브랜치 · 해시 · 번호 — 이 시스템의 시그니처(디자인 시스템 §3).
  TextStyle get mono => TextStyle(
    fontFamily: _mono,
    fontFamilyFallback: _monoFallback,
    fontSize: NxFontSize.xs2,
    height: 1.3,
    color: _c.textSecondary,
    decoration: TextDecoration.none,
  );

  TextStyle get code => mono.copyWith(
    fontSize: NxFontSize.sm,
    height: 1.6,
    color: _c.textPrimary,
  );

  /// 한 줄짜리 경로 · 파일 이름 목록(커밋 · PR 의 바뀐 파일, AI 근거). 코드와 같은
  /// 서체지만 행간이 UI 행간(1.3)이라 줄이 촘촘하다.
  TextStyle get codeLine => mono.copyWith(
    fontSize: NxFontSize.xs,
    height: 1.3,
    color: _c.textPrimary,
  );
}

@immutable
class NxThemeData {
  NxThemeData._(this.brightness, this.colors) : text = NxText._(colors);

  factory NxThemeData.of(Brightness brightness) => NxThemeData._(
    brightness,
    brightness == Brightness.dark ? NxColors.dark : NxColors.light,
  );

  final Brightness brightness;
  final NxColors colors;
  final NxText text;

  bool get isDark => brightness == Brightness.dark;
}

/// 테마를 내려보낸다. **기본 글자 스타일과 아이콘 색을 함께 깐다** — 이것이 없으면
/// `Text` 가 시스템 기본(빨간 밑줄 · 노란 글자)으로 그려진다. Material 이 공짜로 주던 것이다.
class NxTheme extends StatelessWidget {
  const NxTheme({super.key, required this.data, required this.child});

  final NxThemeData data;
  final Widget child;

  static NxThemeData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_NxThemeScope>();
    assert(scope != null, 'NxTheme 이 위에 없다 — 앱 맨 위에 NxTheme 을 깔 것');
    return scope!.data;
  }

  @override
  Widget build(BuildContext context) {
    return _NxThemeScope(
      data: data,
      child: DefaultTextStyle(
        style: data.text.base,
        child: IconTheme(
          data: IconThemeData(color: data.colors.textSecondary, size: 16),
          child: child,
        ),
      ),
    );
  }
}

class _NxThemeScope extends InheritedWidget {
  const _NxThemeScope({required this.data, required super.child});

  final NxThemeData data;

  @override
  bool updateShouldNotify(_NxThemeScope old) =>
      old.data.brightness != data.brightness;
}
