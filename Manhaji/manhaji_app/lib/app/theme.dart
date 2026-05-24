import 'dart:math' as math;

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
  // SPACING SCALE — 8pt grid, named t-shirt sizes (unchanged)
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

  // Legacy aliases (do not remove):
  static const double spacingS = space2;
  static const double spacingM = space4;
  static const double spacingL = space6;

  // ============================================================
  // RADIUS SCALE — slightly softer than Material default,
  // Duolingo-leaning roundness for buttons (rXL).
  // ============================================================

  static const double radiusS = 10;
  static const double radiusM = 14;
  static const double radiusL = 18;
  static const double radiusXL = 22;
  static const double radiusXXL = 28;
  static const double radiusPill = 999;

  // ============================================================
  // ELEVATION TOKENS — warm-tinted shadows that read as
  // "afternoon sun on a courtyard wall" rather than sharp gray.
  // ============================================================

  static List<BoxShadow> get elevationFlat => const [];

  /// Subtle lift for interactive surfaces (cards in lists).
  static List<BoxShadow> get elevationLow => [
        BoxShadow(
          color: const Color(0xFF4A3B1A).withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  /// Default card elevation — visible without dominating.
  static List<BoxShadow> get elevationMedium => [
        BoxShadow(
          color: const Color(0xFF3D2E0F).withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  /// For hero elements (quiz card, completion screen) — almost a halo.
  static List<BoxShadow> get elevationHigh => [
        BoxShadow(
          color: const Color(0xFF3D2E0F).withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: const Color(0xFF3D2E0F).withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// Subject-tinted glow — used on cards that should feel alive.
  static List<BoxShadow> coloredGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.22),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
      ];

  // ============================================================
  // MOTION TOKENS — bouncier than before, kid-app appropriate.
  // ============================================================

  static const Duration motionInstant = Duration(milliseconds: 100);
  static const Duration motionFast = Duration(milliseconds: 180);
  static const Duration motionBase = Duration(milliseconds: 280);
  static const Duration motionSlow = Duration(milliseconds: 450);

  /// Standard easing — gentler than easeOut, lands without overshoot.
  static const Curve motionCurve = Curves.easeOutCubic;

  /// Celebration moments — stars revealing, correct answers, mascot pop.
  /// Slightly less bouncy than elasticOut to avoid nausea on repeat plays.
  static const Curve motionSpring = Curves.elasticOut;

  // ============================================================
  // PRIMARY BRAND PALETTE — Palestinian Playful (renamed values,
  // same symbolic names so callers keep working).
  // ============================================================
  //
  // The names are kept for API compatibility. The actual hues are:
  //   primaryGreen → Olive green (heritage primary)
  //   primaryBlue  → Deep teal   (cool / international)
  //   primaryYellow→ Sunset gold (achievements, stars)
  //   primaryOrange→ Terracotta  (energy, action)
  //   primaryPurple→ Muted plum  (admin/parent accent)
  //   primaryRed   → Watermelon  (errors, meaningful accent)

  static const Color primaryGreen = Color(0xFF5C7A4F);   // olive
  static const Color primaryGreenDeep = Color(0xFF3D5A33);
  static const Color primaryBlue = Color(0xFF2D5A6B);    // deep teal
  static const Color primaryBlueDeep = Color(0xFF1A3F4E);
  static const Color primaryYellow = Color(0xFFF4B942);  // sunset gold
  static const Color primaryYellowDeep = Color(0xFFB8821E);
  static const Color primaryOrange = Color(0xFFD67342);  // terracotta
  static const Color primaryOrangeDeep = Color(0xFFA85525);
  static const Color primaryPurple = Color(0xFF7C4B6F);  // plum
  static const Color primaryRed = Color(0xFFD43F4A);     // watermelon

  // ============================================================
  // SURFACE & TEXT — warm sand foundation
  // ============================================================
  //
  // `backgroundLight` is the page background — warm cream-sand. Cards
  // sit on top in `cardWhite` (pure white) for crisp contrast. Muted/
  // subtle/strong are dividers, disabled chips, focused borders.

  static const Color backgroundLight = Color(0xFFF7F2E4);   // warm sand
  static const Color cardWhite = Color(0xFFFFFFFF);         // crisp white
  static const Color surface = Color(0xFFFCFAF5);           // warm white
  static const Color surfaceMuted = Color(0xFFEFE8D4);      // alt panel
  static const Color surfaceSubtle = Color(0xFFE2D9BE);     // divider
  static const Color surfaceStrong = Color(0xFFCBBE94);     // focused border

  static const Color textDark = Color(0xFF1F2D24);          // olive-black
  static const Color textGray = Color(0xFF5C6A5E);          // warm gray
  static const Color textLight = Color(0xFFA9B0A3);         // muted

  // ============================================================
  // SEMANTIC COLORS — status feedback, two-tone
  // ============================================================

  static const Color success = Color(0xFF4A6741);
  static const Color successContainer = Color(0xFFE5F0DC);

  static const Color warning = Color(0xFFE89B30);
  static const Color warningContainer = Color(0xFFFBE8C2);

  static const Color error = Color(0xFFD43F4A);
  static const Color errorContainer = Color(0xFFFBE0E3);

  static const Color info = Color(0xFF2D5A6B);
  static const Color infoContainer = Color(0xFFD8E6EC);

  // ============================================================
  // SUBJECT THEMES — index matches DataSeeder subject order
  // (0 Arabic / 1 Math / 2 Islamic Education / 3 English).
  // ============================================================
  //
  // Re-themed from the previous Material-clone palette to Palestinian
  // identity colors. Each subject gets a hue with strong cultural
  // resonance plus a soft tint for backgrounds and a two-color
  // gradient for hero cards.

  static const List<Color> subjectColors = [
    Color(0xFF5C7A4F), // 0 Arabic — olive (heritage)
    Color(0xFFD67342), // 1 Math — terracotta (energy)
    Color(0xFFF4B942), // 2 Islamic Education — sunset gold (sacred)
    Color(0xFF2D5A6B), // 3 English — deep teal (international)
  ];

  static const List<Color> subjectLightColors = [
    Color(0xFFE6EEDA), // olive wash
    Color(0xFFF8DDCB), // terracotta wash
    Color(0xFFFBE8C2), // gold wash
    Color(0xFFCEDDE4), // teal wash
  ];

  /// Hero gradients per subject. First color = bright, second = deep.
  static List<List<Color>> get subjectGradients => const [
        [Color(0xFF7C9070), Color(0xFF3D5A33)], // Arabic: olive → deep olive
        [Color(0xFFE89568), Color(0xFFA85525)], // Math: terracotta → burnt sienna
        [Color(0xFFFBD06D), Color(0xFFB8821E)], // Islamic: gold → amber
        [Color(0xFF5680A0), Color(0xFF1A3F4E)], // English: teal → midnight
      ];

  /// Page-wide subtle washes — same hue, much lighter.
  static List<List<Color>> get subjectWashGradients => const [
        [Color(0xFFF1EEDE), Color(0xFFE6EEDA)], // olive
        [Color(0xFFFCF1E6), Color(0xFFF8DDCB)], // terracotta
        [Color(0xFFFEF7E2), Color(0xFFFBE8C2)], // gold
        [Color(0xFFEAF2F6), Color(0xFFCEDDE4)], // teal
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
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: primaryOrange,
        tertiary: primaryYellow,
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
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: space5, vertical: space4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXL),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: surfaceSubtle, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: surfaceSubtle, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: primaryGreen, width: 3),
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
            borderRadius: BorderRadius.circular(radiusXL)),
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
    final effectiveShadow = shadow ??
        (tint != null
            ? AppTheme.coloredGlow(tint!)
            : AppTheme.elevationMedium);

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

// ============================================================
// EightPointStar — Levantine geometric accent
// ============================================================

/// An eight-pointed star, the signature motif of Islamic geometric
/// art and the tilework of every Levantine courtyard. Used as a quiet
/// decorative element in card corners and section dividers — never as
/// a button or interactive element.
///
/// Implemented as a `CustomPaint`, no external image assets.
class EightPointStar extends StatelessWidget {
  final double size;
  final Color color;
  final double rotation;

  const EightPointStar({
    super.key,
    this.size = 24,
    this.color = AppTheme.starGold,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _EightPointStarPainter(color)),
      ),
    );
  }
}

class _EightPointStarPainter extends CustomPainter {
  final Color color;
  _EightPointStarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.55;

    // 16-point path that alternates outer + inner vertices to draw an
    // eight-pointed star (signature Levantine tilework motif).
    final path = Path();
    for (int i = 0; i < 16; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final theta = (i * 22.5) * (math.pi / 180);
      final dx = center.dx + r * math.cos(theta);
      final dy = center.dy + r * math.sin(theta);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_EightPointStarPainter old) => old.color != color;
}
