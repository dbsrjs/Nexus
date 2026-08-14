import 'package:flutter/material.dart';

/// 디자인 토큰. **`design-system/tokens.css` 의 이름을 그대로 옮긴다.**
///
/// 그 파일 상단이 "Flutter core/theme.dart 는 이 파일의 토큰 이름을 그대로
/// 따른다" 고 약속하고 있다. 이름이 갈라지면 디자인 문서와 코드를 대조할 수
/// 없게 되므로, CSS 변수명을 lowerCamelCase 로만 바꿔 1:1 대응시킨다.
///
/// 다크가 기본이다. 토큰 파일이 다크를 `:root` 에 두고 라이트를 뒤집는다.
class NexusColors {
  const NexusColors._();

  // ── 표면 (중성 램프) ──
  static const bgBaseDark = Color(0xFF121314);
  static const bgSurfaceDark = Color(0xFF1C1D1F);
  static const bgElevatedDark = Color(0xFF282A2C);

  static const bgBaseLight = Color(0xFFEFF0F1);
  static const bgSurfaceLight = Color(0xFFF7F8F8);
  static const bgElevatedLight = Color(0xFFFFFFFF);

  // ── 선 ──
  // divider 는 구조 구분선이라 거의 보이지 않아야 하고(≈1.3:1),
  // borderStrong 은 비활성 아이콘·입력 테두리라 읽혀야 한다(≈3:1).
  static const dividerDark = Color(0x1ADDE6ED); // rgba(221,230,237,.10)
  static const borderStrongDark = Color(0xFF63676B);

  static const dividerLight = Color(0x1C121314); // rgba(18,19,20,.11)
  static const borderStrongLight = Color(0xFFA8ABAE);

  // ── 텍스트 ──
  static const textPrimaryDark = Color(0xFFDDE6ED);
  static const textSecondaryDark = Color(0xFF9DA0A4);

  static const textPrimaryLight = Color(0xFF27374D);
  static const textSecondaryLight = Color(0xFF5E6165);

  // ── 액센트 ──
  static const accentDark = Color(0xFF77AECF);
  static const accentSubtleDark = Color(0x2177AECF); // rgba(119,174,207,.13)
  static const accentPressDark = Color(0xFF5197C2);

  static const accentLight = Color(0xFF326C8F);
  static const accentSubtleLight = Color(0x17326C8F); // rgba(50,108,143,.09)
  static const accentPressLight = Color(0xFF285571);

  // ── 시맨틱 (면적을 좁게 쓴다) ──
  static const success = Color(0xFF74B48F);
  static const warning = Color(0xFFD3B069);
  static const danger = Color(0xFFD47D7D);
  static const merged = Color(0xFFA18ECC);

  /// 아바타 8색. 채도 28% · 명도 66% 고정, 색상만 균등 분배.
  /// 배정은 `hash(userId) % 8` — 같은 사람은 어디서든 같은 색이다.
  static const avatars = <Color>[
    Color(0xFF90A8C1),
    Color(0xFF9C90C1),
    Color(0xFFC190C1),
    Color(0xFFC1909C),
    Color(0xFFC1A890),
    Color(0xFFB4C190),
    Color(0xFF90C1A0),
    Color(0xFF90C1C1),
  ];
}

/// 간격 — 4px 그리드. 화면 코드에 매직 넘버를 쓰지 않기 위해 미리 옮겨 둔다.
class NexusSpacing {
  const NexusSpacing._();

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

/// 형태.
class NexusRadius {
  const NexusRadius._();

  static const double sm = 4;
  static const double md = 6;
  static const double full = 9999;
}

/// 모션.
class NexusMotion {
  const NexusMotion._();

  static const micro = Duration(milliseconds: 120);
  static const panel = Duration(milliseconds: 180);
  static const ease = Cubic(0, 0, 0.2, 1);
}

/// 타이포 크기. 토큰 이름을 그대로 쓴다.
class NexusTextSizes {
  const NexusTextSizes._();

  static const double text2xs = 11;
  static const double textXs = 12;
  static const double textSm = 13;
  static const double textBase = 14;
  static const double textMd = 16;
  static const double textLg = 20;
  static const double textXl = 24;

  static const double leadingBody = 1.5;
  static const double leadingUi = 1.3;
}

/// 폰트는 아직 번들하지 않는다. `Pretendard` 가 설치돼 있으면 쓰이고, 없으면
/// 시스템 폰트로 떨어진다. 자산 번들은 화면이 여러 개가 될 때 넣는다.
const _fontFamily = 'Pretendard';
const _fontFallback = <String>['Segoe UI', 'Noto Sans KR'];

ThemeData buildNexusTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;

  final bgBase = isDark ? NexusColors.bgBaseDark : NexusColors.bgBaseLight;
  final bgSurface =
      isDark ? NexusColors.bgSurfaceDark : NexusColors.bgSurfaceLight;
  final bgElevated =
      isDark ? NexusColors.bgElevatedDark : NexusColors.bgElevatedLight;
  final divider = isDark ? NexusColors.dividerDark : NexusColors.dividerLight;
  final borderStrong =
      isDark ? NexusColors.borderStrongDark : NexusColors.borderStrongLight;
  final textPrimary =
      isDark ? NexusColors.textPrimaryDark : NexusColors.textPrimaryLight;
  final textSecondary =
      isDark ? NexusColors.textSecondaryDark : NexusColors.textSecondaryLight;
  final accent = isDark ? NexusColors.accentDark : NexusColors.accentLight;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: bgBase,
    secondary: accent,
    onSecondary: bgBase,
    error: NexusColors.danger,
    onError: bgBase,
    surface: bgSurface,
    onSurface: textPrimary,
  );

  TextStyle body(double size, {FontWeight? weight, Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: size,
        height: NexusTextSizes.leadingBody,
        fontWeight: weight,
        color: color ?? textPrimary,
      );

  TextStyle ui(double size, {FontWeight? weight, Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: size,
        height: NexusTextSizes.leadingUi,
        fontWeight: weight,
        color: color ?? textPrimary,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bgBase,
    canvasColor: bgSurface,
    dividerColor: divider,
    dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
    textTheme: TextTheme(
      headlineSmall: ui(NexusTextSizes.textXl, weight: FontWeight.w600),
      titleLarge: ui(NexusTextSizes.textLg, weight: FontWeight.w600),
      titleMedium: ui(NexusTextSizes.textMd, weight: FontWeight.w600),
      bodyLarge: body(NexusTextSizes.textMd),
      bodyMedium: body(NexusTextSizes.textBase),
      bodySmall: body(NexusTextSizes.textSm, color: textSecondary),
      labelSmall: ui(NexusTextSizes.textXs, color: textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgElevated,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: NexusSpacing.sp5,
        vertical: NexusSpacing.sp5,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusRadius.md),
        borderSide: BorderSide(color: borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusRadius.md),
        borderSide: BorderSide(color: borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusRadius.md),
        borderSide: BorderSide(color: accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusRadius.md),
        borderSide: const BorderSide(color: NexusColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusRadius.md),
        borderSide: const BorderSide(color: NexusColors.danger, width: 2),
      ),
      labelStyle: ui(NexusTextSizes.textBase, color: textSecondary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: bgBase,
        padding: const EdgeInsets.symmetric(
          horizontal: NexusSpacing.sp6,
          vertical: NexusSpacing.sp5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexusRadius.md),
        ),
        textStyle: ui(NexusTextSizes.textBase, weight: FontWeight.w600),
      ),
    ),
  );
}
