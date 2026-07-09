import '../models/progress.dart';

/// Tier 3 (2026-07) — gamification registry: levels, avatars, badges.
///
/// Everything here is computed CLIENT-SIDE from data the backend already
/// serves (`totalPoints`, `currentStreak`, `completedLessons`,
/// `masteredLessons`). Only the chosen avatar id round-trips to the server
/// (`PUT /api/student/avatar`); unlock thresholds are a UI concern.

// ─────────────────────────────────────────────────────────────
// Level system — 6 ranks from مبتدئ to أسطورة.
// ─────────────────────────────────────────────────────────────
class LevelDef {
  final int level;
  final String title;
  final String emoji;
  final int minPts;
  final int maxPts;

  const LevelDef(this.level, this.title, this.emoji, this.minPts, this.maxPts);

  /// 0..1 progress within this level's band (max level pins to 1).
  double progress(int pts) {
    final span = maxPts - minPts;
    if (span <= 0) return 1.0;
    return ((pts - minPts) / span).clamp(0.0, 1.0);
  }

  int remaining(int pts) => (maxPts - pts).clamp(0, maxPts);
  bool get isMax => level == kLevels.length;
}

const kLevels = [
  LevelDef(1, 'مبتدئ', '🌱', 0, 500),
  LevelDef(2, 'مستكشف', '🔍', 500, 1000),
  LevelDef(3, 'باحث', '📚', 1000, 1500),
  LevelDef(4, 'بطل', '🏆', 1500, 2000),
  LevelDef(5, 'خبير', '🌟', 2000, 2500),
  LevelDef(6, 'أسطورة', '👑', 2500, 2500),
];

LevelDef levelOf(int pts) {
  for (final l in kLevels.reversed) {
    if (pts >= l.minPts) return l;
  }
  return kLevels.first;
}

// ─────────────────────────────────────────────────────────────
// Avatar registry — the id (e.g. "fox") is what's stored on the
// Student row; emoji/name/threshold live only here.
// ─────────────────────────────────────────────────────────────
class AvatarDef {
  final String id;
  final String emoji;
  final String name;
  final int unlockPoints;

  const AvatarDef(this.id, this.emoji, this.name, this.unlockPoints);

  bool isUnlocked(int userPoints) => userPoints >= unlockPoints;
}

class Avatars {
  Avatars._();

  static const AvatarDef fallback = AvatarDef('rabbit', '🐰', 'الأرنب', 0);

  /// Ascending by unlock threshold so the grid reads as a progression.
  static const List<AvatarDef> all = [
    AvatarDef('rabbit', '🐰', 'الأرنب', 0),
    AvatarDef('unicorn', '🦄', 'اليونيكورن', 0),
    AvatarDef('butterfly', '🦋', 'الفراشة', 0),
    AvatarDef('panda', '🐼', 'الباندا', 0),
    AvatarDef('hamster', '🐹', 'الهامستر', 0),
    AvatarDef('koala', '🐨', 'الكوالا', 0),
    AvatarDef('penguin', '🐧', 'البطريق', 0),
    AvatarDef('fox', '🦊', 'الثعلب', 500),
    AvatarDef('owl', '🦉', 'البومة', 1000),
    AvatarDef('turtle', '🐢', 'السلحفاة', 1500),
    AvatarDef('bee', '🐝', 'النحلة', 2000),
    AvatarDef('dolphin', '🐬', 'الدلفين', 2500),
    AvatarDef('otter', '🦦', 'القضاعة', 3000),
    AvatarDef('sloth', '🦥', 'الكسلان', 3500),
    AvatarDef('bear', '🐻', 'الدب', 4000),
    AvatarDef('lion', '🦁', 'الأسد', 5000),
    AvatarDef('robot', '🤖', 'الروبوت', 6500),
    AvatarDef('dragon', '🐲', 'التنين', 8000),
    AvatarDef('queen', '👸', 'الملكة', 10000),
    AvatarDef('king', '👑', 'الملك', 12000),
  ];

  /// Avatars whose threshold was crossed between [oldPoints] and [newPoints]
  /// — used after a quiz to celebrate fresh unlocks. Free avatars never count.
  static List<AvatarDef> newlyUnlocked(int oldPoints, int newPoints) => all
      .where((a) =>
          a.unlockPoints > 0 &&
          oldPoints < a.unlockPoints &&
          newPoints >= a.unlockPoints)
      .toList();

  /// Accepts an id ("fox"), a legacy raw emoji, or null. Never throws.
  static AvatarDef resolve(String? raw) {
    if (raw == null || raw.isEmpty) return fallback;
    for (final a in all) {
      if (a.id == raw) return a;
    }
    for (final a in all) {
      if (a.emoji == raw) return a;
    }
    return fallback;
  }
}

// ─────────────────────────────────────────────────────────────
// Achievement badges — computed from ProgressSummary.
// ─────────────────────────────────────────────────────────────
class GamBadge {
  final String emoji;
  final String title;
  final String desc;
  final bool unlocked;

  const GamBadge(this.emoji, this.title, this.desc, this.unlocked);
}

List<GamBadge> buildBadges(ProgressSummary? p) => [
      GamBadge('👣', 'أول خطوة', 'أكمل أول درس', (p?.completedLessons ?? 0) >= 1),
      GamBadge('⚡', 'متعلم سريع', 'أكمل 5 دروس', (p?.completedLessons ?? 0) >= 5),
      GamBadge('📖', 'قارئ نشيط', 'أكمل 10 دروس', (p?.completedLessons ?? 0) >= 10),
      GamBadge('🔥', 'أسبوع متواصل', '7 أيام متتالية', (p?.currentStreak ?? 0) >= 7),
      GamBadge('⭐', 'جامع النقاط', 'اكسب 500 نقطة', (p?.totalPoints ?? 0) >= 500),
      GamBadge('🎯', 'المتقن', 'أتقن 3 دروس', (p?.masteredLessons ?? 0) >= 3),
    ];
