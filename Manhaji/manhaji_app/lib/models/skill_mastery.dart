/// Per-subject skill-mastery snapshot for the "My Skills" radar chart.
/// Mirrors the backend `SkillMasteryResponse` DTO.
class SkillMastery {
  final int subjectId;
  final String subjectName;
  final List<SkillScore> skills;

  SkillMastery({
    required this.subjectId,
    required this.subjectName,
    required this.skills,
  });

  factory SkillMastery.fromJson(Map<String, dynamic> json) {
    return SkillMastery(
      subjectId: json['subjectId'] ?? 0,
      subjectName: json['subjectName'] ?? '',
      skills: (json['skills'] as List?)
              ?.map((s) => SkillScore.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class SkillScore {
  final String subSkill;
  /// Bayesian Knowledge Tracing P(mastered), 0.0–1.0.
  final double pMastery;
  /// How many answers informed this estimate (0 = never practised).
  final int observationCount;
  final bool mastered;

  SkillScore({
    required this.subSkill,
    required this.pMastery,
    required this.observationCount,
    required this.mastered,
  });

  factory SkillScore.fromJson(Map<String, dynamic> json) {
    return SkillScore(
      subSkill: json['subSkill'] ?? '',
      pMastery: (json['pMastery'] ?? 0.0).toDouble(),
      observationCount: json['observationCount'] ?? 0,
      mastered: json['mastered'] ?? false,
    );
  }

  /// Mastery as a 0–100 percentage for display.
  int get percent => (pMastery * 100).round();

  /// Arabic display label for the sub-skill axis. Falls back to the raw
  /// tag if unknown, so a new backend sub-skill never renders blank.
  String get arabicLabel => _arabicLabels[subSkill] ?? subSkill;

  static const Map<String, String> _arabicLabels = {
    'recognition': 'التعرّف',
    'comprehension': 'الفهم',
    'production': 'الإنتاج',
    'application': 'التطبيق',
    'computation': 'الحساب',
    'pronunciation': 'النطق',
    'recitation': 'التلاوة',
    'memorization': 'الحفظ',
    'handwriting': 'الكتابة',
    'reading': 'القراءة',
  };
}
