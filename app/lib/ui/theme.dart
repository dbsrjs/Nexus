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
}

class NxRadius {
  const NxRadius._();

  static const double sm = 4;
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
  TextStyle get xs2 => _ui(11);
  TextStyle get xs => _ui(12);
  TextStyle get sm => _ui(13);
  TextStyle get base => _ui(14);
  TextStyle get md => _ui(16);
  TextStyle get lg => _ui(20);
  TextStyle get xl => _ui(24);

  /// **읽는 본문** — 메시지 · 이슈 본문 · 댓글. 15px · 행간 1.6.
  TextStyle get body => _ui(15).copyWith(height: 1.6);

  // ── 쓰임새 ──
  TextStyle get heading => _ui(20, weight: FontWeight.w700);
  TextStyle get title => _ui(16, weight: FontWeight.w600);
  TextStyle get strong => _ui(14, weight: FontWeight.w600);
  TextStyle get secondary => _ui(13, color: _c.textSecondary);
  TextStyle get meta => _ui(12, color: _c.textSecondary);

  /// 섹션 머리(「작업」 · 「일반」). 대문자가 없는 한글이라 자간만 조금 연다.
  TextStyle get label => _ui(
    11,
    weight: FontWeight.w600,
    color: _c.borderStrong,
  ).copyWith(letterSpacing: 0.6);

  /// 타임스탬프 · 브랜치 · 해시 · 번호 — 이 시스템의 시그니처(디자인 시스템 §3).
  TextStyle get mono => TextStyle(
    fontFamily: _mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 11,
    height: 1.3,
    color: _c.textSecondary,
    decoration: TextDecoration.none,
  );

  TextStyle get code =>
      mono.copyWith(fontSize: 13, height: 1.6, color: _c.textPrimary);
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
