import 'package:flutter/material.dart';

/// Manhaji design system — Palestinian Playful edition (2026-05-24).
///
/// One source of truth for color, spacing, radius, elevation, motion, and
/// typography. Palette is rooted in Palestinian visual identity — olive
/// green (heritage, primary action), terracotta (warmth, energy), sunset
/// gold (achievements, sacred), watermelon red (errors and a meaningful
/// accent), warm sand backgrounds — paired with kid-friendly motion and
/// spacing tuned for 6-year-old fingers.
///
/// **API stability:** every `AppTheme.*` symbol name from the previous
/// theme is preserved so the 80+ widgets across the app keep compiling
/// without per-widget edits. Only the *values* change. Subject indices
/// also stay aligned with the entity order (Arabic / Math / Islamic /
/// English) so JSON-driven subject lookups keep working.
class AppTheme {
  // ============================================================
  // SPACING SCALE — 8pt grid, named t-shirt sizes
  // ============================================================

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;

  // Legacy aliases
  static const double spacingS = space2;
  static const double spacingM = space4;
  static const double spacingL = space6;

  // ============================================================
  // RADIUS SCALE — Duolingo-style bubbly roundness
  // ============================================================

  static const double radiusS = 12;
  static const double radiusM = 16;
  static const double radiusL = 20;
  static const double radiusXL = 24;
  static const double radiusXXL = 32;
  static const double radiusPill = 999;

  // ============================================================
  // ELEVATION & DEPTH TOKENS
  // ============================================================

  /// Standard Duolingo-style "3D" depth for buttons.
  static const double buttonDepth = 4.0;
  static const double buttonDepthPressed = 0.0;

  static List<BoxShadow> get elevationLow => [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevationMedium => [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  // ============================================================
  // MOTION TOKENS
  // ============================================================

  static const Duration motionInstant = Duration(milliseconds: 80);
  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionBase = Duration(milliseconds: 250);
  static const Duration motionSlow = Duration(milliseconds: 400);

  static const Curve motionCurve = Curves.easeOutCubic;
  static const Curve motionSpring = Curves.elasticOut;

  // ============================================================
  // VIBRANT BRAND PALETTE — Duolingo Inspired
  // ============================================================

  static const Color primaryGreen = Color(0xFF58CC02);   // Duolingo green (semantic success / correct answers)
  static const Color primaryGreenDeep = Color(0xFF46A302);

  // ── BRAND PRIMARY — warm terracotta (2026-06 re-skin to the warm theme) ──
  // The app's brand/action color. Used by the Material theme, DuolingoButton
  // default, app bar, and primary CTAs. `primaryGreen` is kept as-is so
  // correct-answer/success feedback stays green.
  static const Color primaryTerracotta = Color(0xFFE87F24);
  static const Color primaryTerracottaDeep = Color(0xFFC96A10);

  static const Color primaryBlue = Color(0xFF73A5CA);    // Dusty blue (her secondary)
  static const Color primaryBlueDeep = Color(0xFF5A8AAD);

  static const Color primaryYellow = Color(0xFFFFC81E);  // Warm gold
  static const Color primaryYellowDeep = Color(0xFFD4A400);

  static const Color primaryOrange = Color(0xFFFF9600);  // Flame orange (accents)
  static const Color primaryOrangeDeep = Color(0xFFE58700);
  
  static const Color primaryPurple = Color(0xFFCE82FF);  // Bright purple
  static const Color primaryPurpleDeep = Color(0xFFA568CC);
  
  static const Color primaryRed = Color(0xFFFF4B4B);     // Flamingo red
  static const Color primaryRedDeep = Color(0xFFD33131);

  // ============================================================
  // SURFACE & TEXT
  // ============================================================

  // ── WARM CREAM SURFACES (2026-06 re-skin) ──
  static const Color backgroundLight = Color(0xFFFEFDDF);   // Signature warm cream
  static const Color backgroundMint = Color(0xFFFBF7E4);    // Soft cream variant
  static const Color backgroundGold = Color(0xFFFFFBF0);    // Very soft gold

  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFBF7E4);           // Warm cream surface
  static const Color surfaceMuted = Color(0xFFE8DCC8);      // Sand border/divider
  static const Color surfaceSubtle = Color(0xFFF5EFDD);     // Subtle cream alt
  static const Color surfaceStrong = Color(0xFFC4B696);     // Muted sand text/border
  static const Color surfaceBlue = Color(0xFFE0EEF8);       // Soft blue (path/progress bg)

  static const Color textDark = Color(0xFF3C3C3C);          // Warm charcoal text
  static const Color textGray = Color(0xFF7A7A7A);          // Medium gray text
  static const Color textLight = Color(0xFFAFAFAF);         // Muted text

  // ============================================================
  // SEMANTIC COLORS
  // ============================================================

  static const Color success = Color(0xFF58CC02);
  static const Color successContainer = Color(0xFFD7FFB8);

  static const Color warning = Color(0xFFFFC800);
  static const Color warningContainer = Color(0xFFFFF4D1);

  static const Color error = Color(0xFFFF4B4B);
  static const Color errorContainer = Color(0xFFFFDFE0);

  static const Color info = Color(0xFF1CB0F6);
  static const Color infoContainer = Color(0xFFDDF4FF);

  // ============================================================
  // SUBJECT THEMES
  // ============================================================

  static const List<Color> subjectColors = [
    primaryGreen,   // 0 Arabic
    primaryBlue,    // 1 Math
    primaryYellow,  // 2 Islamic
    primaryOrange,  // 3 English
  ];

  static const List<Color> subjectLightColors = [
    Color(0xFFD7FFB8),
    Color(0xFFDDF4FF),
    Color(0xFFFFF4D1),
    Color(0xFFFFEAD1),
  ];

  static List<List<Color>> get subjectGradients => const [
        [primaryGreen, primaryGreenDeep],
        [primaryBlue, primaryBlueDeep],
        [primaryYellow, primaryYellowDeep],
        [primaryOrange, primaryOrangeDeep],
      ];

  /// Page-wide subtle washes — warm cream family so every subject page
  /// keeps the signature warm background (2026-06 re-skin).
  static List<List<Color>> get subjectWashGradients => const [
        [Color(0xFFFEFDDF), Color(0xFFF6EFD6)], // cream → soft sand
        [Color(0xFFFEFBEF), Color(0xFFFBEAD3)], // cream → warm terracotta tint
        [Color(0xFFFEFDDF), Color(0xFFFBF1C9)], // cream → gold tint
        [Color(0xFFFAFBEB), Color(0xFFE6EEDC)], // cream → soft sage
      ];

  // ============================================================
  // QUESTION-TYPE COLORS — accent per kind of question
  // ============================================================
  //
  // Used on the type pill at the top of the quiz card and on chips
  // in the question bank. Pulled into the Palestinian palette.

  static Color colorForQuestionType(String type) {
    switch (type) {
      case 'MCQ':
        return primaryBlue;            // deep teal
      case 'TRUE_FALSE':
        return primaryPurple;          // plum
      case 'SHORT_ANSWER':
        return primaryOrange;          // terracotta
      case 'FILL_BLANK':
        return const Color(0xFF3A8378); // forest teal
      case 'ORDERING':
        return const Color(0xFF8B5A8C); // mulberry
      case 'PRONUNCIATION':
        return primaryRed;             // watermelon (voice = vivid)
      case 'TRACING':
        return const Color(0xFF8B6B47); // umber
      default:
        return primaryGreen;
    }
  }

  static String emojiForQuestionType(String type) {
    switch (type) {
      case 'MCQ':
        return '🎯';
      case 'TRUE_FALSE':
        return '⚖️';
      case 'SHORT_ANSWER':
        return '✏️';
      case 'FILL_BLANK':
        return '🧩';
      case 'ORDERING':
        return '🔢';
      case 'PRONUNCIATION':
        return '🎤';
      case 'TRACING':
        return '🖌️';
      default:
        return '📚';
    }
  }

  static String labelForQuestionType(String type) {
    switch (type) {
      case 'MCQ':
        return 'اختر الإجابة';
      case 'TRUE_FALSE':
        return 'صح أو خطأ';
      case 'SHORT_ANSWER':
        return 'إجابة قصيرة';
      case 'FILL_BLANK':
        return 'أكمل الفراغ';
      case 'ORDERING':
        return 'رتّب العناصر';
      case 'PRONUNCIATION':
        return 'انطق الكلمة';
      case 'TRACING':
        return 'ارسم الحرف';
      default:
        return '';
    }
  }

  // ============================================================
  // STAR COLORS — quiz reward, deeper gold than before
  // ============================================================

  static const Color starGold = Color(0xFFF4B942);
  static const Color starGoldDeep = Color(0xFFB8821E);
  static const Color starInactive = Color(0xFFD6CCB5);

  // ============================================================
  // TYPOGRAPHY SCALE — Cairo (Arabic) with bolder weight bias
  // ============================================================

  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 38,
    fontWeight: FontWeight.w800,
    color: textDark,
    height: 1.2,
    letterSpacing: -0.5,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textDark,
    height: 1.25,
    letterSpacing: -0.25,
  );
  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textDark,
    height: 1.3,
  );
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textDark,
    height: 1.3,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textDark,
    height: 1.35,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textDark,
    height: 1.4,
  );
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textDark,
    height: 1.5,
  );
  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textDark,
    height: 1.5,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textDark,
    height: 1.6,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textGray,
    height: 1.6,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textLight,
    height: 1.5,
  );
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: textDark,
    letterSpacing: 0.4,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: textGray,
    letterSpacing: 0.4,
  );

  // The big, friendly text used on the quiz question itself.
  static const TextStyle questionPrompt = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textDark,
    height: 1.6,
  );

  // ============================================================
  // THEMEDATA — wires the palette into Material widgets
  // ============================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTerracotta,
        brightness: Brightness.light,
        primary: primaryTerracotta,
        secondary: primaryBlue,
        tertiary: primaryYellow,
        surface: cardWhite,
        error: error,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: 0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTerracotta,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: space5, vertical: space4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSubtle,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: surfaceMuted, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: surfaceMuted, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(
            fontFamily: 'Cairo', fontSize: 16, color: textGray),
        hintStyle: const TextStyle(
            fontFamily: 'Cairo', fontSize: 14, color: textLight),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardWhite,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL)),
        margin:
            const EdgeInsets.symmetric(horizontal: space4, vertical: space2),
      ),
      textTheme: const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
      ),
    );
  }
}

// ============================================================
// AppGap — typed-size SizedBox (unchanged API)
// ============================================================

class AppGap extends StatelessWidget {
  final double height;
  final double width;
  const AppGap._({this.height = 0, this.width = 0});

  // Vertical gaps
  const AppGap.v1() : this._(height: AppTheme.space1);
  const AppGap.v2() : this._(height: AppTheme.space2);
  const AppGap.v3() : this._(height: AppTheme.space3);
  const AppGap.v4() : this._(height: AppTheme.space4);
  const AppGap.v5() : this._(height: AppTheme.space5);
  const AppGap.v6() : this._(height: AppTheme.space6);
  const AppGap.v8() : this._(height: AppTheme.space8);
  const AppGap.v10() : this._(height: AppTheme.space10);
  const AppGap.v12() : this._(height: AppTheme.space12);

  // Horizontal gaps
  const AppGap.h1() : this._(width: AppTheme.space1);
  const AppGap.h2() : this._(width: AppTheme.space2);
  const AppGap.h3() : this._(width: AppTheme.space3);
  const AppGap.h4() : this._(width: AppTheme.space4);
  const AppGap.h6() : this._(width: AppTheme.space6);

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: height, width: width);
}

// ============================================================
// AppCard — branded card (unchanged API, palette flows through)
// ============================================================

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final List<BoxShadow>? shadow;
  final Color? tint;
  final List<Color>? gradient;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppTheme.radiusXL,
    this.shadow,
    this.tint,
    this.gradient,
    this.borderColor,
    this.borderWidth = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveShadow = shadow ?? AppTheme.elevationLow;

    final decoration = BoxDecoration(
      color: gradient == null ? AppTheme.cardWhite : null,
      gradient: gradient != null
          ? LinearGradient(
              colors: gradient!,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: effectiveShadow,
      border: borderColor != null
          ? Border.all(color: borderColor!, width: borderWidth)
          : null,
    );

    final body = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.space5),
      decoration: decoration,
      child: child,
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: body,
      ),
    );
  }
}
