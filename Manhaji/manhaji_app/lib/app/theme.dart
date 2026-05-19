import 'package:flutter/material.dart';

/// Manhaji design system.
///
/// One source of truth for color, spacing, radius, elevation, motion, and
/// typography across the app. Widgets should consume these tokens instead
/// of inlining magic numbers — that's how we keep the kid-facing UI
/// visually consistent without per-screen ad-hoc styling.
///
/// All Grade 1 era constants (primaryGreen, spacingS/M/L, etc.) are kept
/// so existing widgets continue to compile unchanged. New widgets should
/// prefer the richer tokens defined below.
class AppTheme {
  // ============================================================
  // SPACING SCALE — 8pt grid, named t-shirt sizes
  // ============================================================
  //
  // Use these everywhere instead of hardcoded SizedBox(height: 12). The
  // legacy spacingS/M/L still resolve to space2/space4/space6 for
  // backwards compatibility with widgets written before this overhaul.

  static const double space1 = 4;    // xs — tightest, between an icon and its label
  static const double space2 = 8;    // sm — between siblings in a row
  static const double space3 = 12;   // — between related blocks
  static const double space4 = 16;   // md — default gap between elements
  static const double space5 = 20;   // — between sections inside a card
  static const double space6 = 24;   // lg — between cards in a list
  static const double space8 = 32;   // xl — between page sections
  static const double space10 = 40;  // — for hero spacing on splash/result
  static const double space12 = 48;  // xxl — top of page above hero

  // Legacy aliases (do not remove — referenced from many widgets):
  static const double spacingS = space2;
  static const double spacingM = space4;
  static const double spacingL = space6;

  // ============================================================
  // RADIUS SCALE — softer than Material default, kid-friendly
  // ============================================================

  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;
  static const double radiusPill = 999; // for tags / chips / fully-rounded

  // ============================================================
  // ELEVATION TOKENS — soft, layered shadows
  // ============================================================
  //
  // Instead of Material's box-shadow defaults (often too dark on light
  // backgrounds), we use brand-tinted, low-opacity shadows. Use the
  // helper getters below; never inline a BoxShadow constructor.

  static List<BoxShadow> get elevationFlat => const [];

  static List<BoxShadow> get elevationLow => [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevationMedium => [
        BoxShadow(
          color: const Color(0xFF1A1F36).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevationHigh => [
        BoxShadow(
          color: const Color(0xFF1A1F36).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF1A1F36).withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Subject-tinted glow for cards that should feel "alive" — used on the
  /// quiz card so it reads as friendly rather than clinical.
  static List<BoxShadow> coloredGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];

  // ============================================================
  // MOTION TOKENS
  // ============================================================

  static const Duration motionInstant = Duration(milliseconds: 100);
  static const Duration motionFast = Duration(milliseconds: 180);
  static const Duration motionBase = Duration(milliseconds: 280);
  static const Duration motionSlow = Duration(milliseconds: 450);

  /// Standard easing for entrances/exits — feels organic, not robotic.
  static const Curve motionCurve = Curves.easeOutCubic;

  /// Springy curve for celebration moments (correct answers, star reveals).
  static const Curve motionSpring = Curves.elasticOut;

  // ============================================================
  // PRIMARY BRAND PALETTE — kept identical to Grade 1 era
  // ============================================================

  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color primaryRed = Color(0xFFF44336);

  // ============================================================
  // SURFACE & TEXT — slightly cooled vs old palette
  // ============================================================

  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textGray = Color(0xFF636E72);
  static const Color textLight = Color(0xFFB2BEC3);

  // New, layered surfaces — use these for nested cards/panels:
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF7F9FC);   // page bg behind cards
  static const Color surfaceSubtle = Color(0xFFEEF1F6);  // disabled state, divider
  static const Color surfaceStrong = Color(0xFFE2E8F0);  // border on focus

  // ============================================================
  // SEMANTIC COLORS — for status indicators, alerts, feedback
  // ============================================================
  //
  // Two-tone (foreground + container) so we can use container tints
  // for bg fills while keeping the strong tone for icons/text.

  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // ============================================================
  // SUBJECT THEMES — gradients, accents, friendly icons
  // ============================================================
  //
  // Each subject gets a two-color gradient for hero cards and an accent
  // color for buttons/chips. Indexes match enum order in `Subject`.

  static const List<Color> subjectColors = [
    Color(0xFF2196F3), // 0: Arabic — Blue
    Color(0xFF4CAF50), // 1: Math   — Green
    Color(0xFF9C27B0), // 2: Islamic Education — Purple
    Color(0xFFFF9800), // 3: English (or Science) — Orange
  ];

  static const List<Color> subjectLightColors = [
    Color(0xFFE3F2FD),
    Color(0xFFE8F5E9),
    Color(0xFFF3E5F5),
    Color(0xFFFFF3E0),
  ];

  /// Two-color gradient per subject for hero cards on Home / Subject screens.
  static List<List<Color>> get subjectGradients => const [
        [Color(0xFF60A5FA), Color(0xFF2563EB)], // Arabic — sky → blue
        [Color(0xFF6EE7B7), Color(0xFF059669)], // Math — mint → emerald
        [Color(0xFFC084FC), Color(0xFF7C3AED)], // Islamic — lavender → violet
        [Color(0xFFFBBF24), Color(0xFFD97706)], // English — amber → gold
      ];

  /// Soft "wash" gradient (lighter than subjectGradients) used as full-page
  /// backgrounds on subject screens. Keeps the brand color present without
  /// being overwhelming behind dense content.
  static List<List<Color>> get subjectWashGradients => const [
        [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
        [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
        [Color(0xFFFAF5FF), Color(0xFFEDE9FE)],
        [Color(0xFFFEFCE8), Color(0xFFFEF3C7)],
      ];

  // ============================================================
  // QUESTION-TYPE COLORS — for badges and accents
  // ============================================================
  //
  // Each of the 7 question types gets a distinct color + emoji so kids
  // can recognize them at a glance.

  static Color colorForQuestionType(String type) {
    switch (type) {
      case 'MCQ':
        return primaryBlue;
      case 'TRUE_FALSE':
        return primaryPurple;
      case 'SHORT_ANSWER':
        return primaryOrange;
      case 'FILL_BLANK':
        return const Color(0xFF00897B);
      case 'ORDERING':
        return const Color(0xFF7B1FA2);
      case 'PRONUNCIATION':
        return const Color(0xFFE91E63);
      case 'TRACING':
        return const Color(0xFF795548);
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
  // STAR COLORS — for the result/reward screen
  // ============================================================

  static const Color starGold = Color(0xFFFCD34D);
  static const Color starGoldDeep = Color(0xFFD97706);
  static const Color starInactive = Color(0xFFE5E7EB);

  // ============================================================
  // TYPOGRAPHY SCALE
  // ============================================================
  //
  // Modular scale 1.25x. Heights tuned for Arabic which needs more
  // line-height than Latin to render diacritics cleanly. All explicit
  // letterSpacing so reflowed text stays consistent.

  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 36,
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
    fontWeight: FontWeight.w600,
    color: textDark,
    height: 1.4,
  );
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textDark,
    height: 1.5,
  );
  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 16,
    fontWeight: FontWeight.w600,
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
    fontWeight: FontWeight.w700,
    color: textDark,
    letterSpacing: 0.5,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: textGray,
    letterSpacing: 0.5,
  );

  // The big, friendly text used on the quiz question itself.
  static const TextStyle questionPrompt = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textDark,
    height: 1.6,
  );

  // ============================================================
  // THEMEDATA
  // ============================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: primaryBlue,
        surface: cardWhite,
        error: error,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
        hintStyle: const TextStyle(
            fontFamily: 'Cairo', fontSize: 14, color: textLight),
      ),
      cardTheme: CardThemeData(
        elevation: 0, // we paint elevation manually via `elevationLow/Medium/High`
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusL)),
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
// AppGap — readable replacement for `SizedBox(height: AppTheme.space4)`
// ============================================================

/// Reads as `const AppGap.v4()` for vertical 16dp gap, `AppGap.h6()` for
/// horizontal 24dp. Saves boilerplate and keeps all spacing on the scale.
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
// AppCard — branded card with elevation tokens and optional gradient
// ============================================================

/// Replaces ad-hoc `Container(decoration: BoxDecoration(...))` for cards.
/// Use `tint` to give the card a subject-colored glow; use `gradient` for
/// hero cards on Home / Subject screens.
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
    final effectiveShadow = shadow ??
        (tint != null
            ? AppTheme.coloredGlow(tint!)
            : AppTheme.elevationMedium);

    final decoration = BoxDecoration(
      color: gradient == null ? AppTheme.surface : null,
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
