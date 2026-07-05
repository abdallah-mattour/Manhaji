class PronunciationScore {
  final int questionId;
  final String expectedText;
  final String transcribedText;
  final int score;
  final String rating;
  final String feedback;
  final bool isCorrect;
  final int pointsEarned;

  /// Feature B (2026-04-29): phonemes / letters the child mispronounced
  /// (e.g. ["ر","ع"]). Empty list when AI didn't return any or wasn't available.
  final List<String> phonemeErrors;

  /// Feature B (2026-04-29): a single short Arabic coaching sentence from Gemini.
  /// Null when AI not available; the UI hides the coaching card in that case.
  final String? guidance;

  PronunciationScore({
    required this.questionId,
    required this.expectedText,
    required this.transcribedText,
    required this.score,
    required this.rating,
    required this.feedback,
    required this.isCorrect,
    required this.pointsEarned,
    this.phonemeErrors = const [],
    this.guidance,
  });

  factory PronunciationScore.fromJson(Map<String, dynamic> json) {
    return PronunciationScore(
      questionId: json['questionId'] ?? 0,
      expectedText: json['expectedText'] ?? '',
      transcribedText: json['transcribedText'] ?? '',
      score: json['score'] ?? 0,
      rating: json['rating'] ?? '',
      feedback: json['feedback'] ?? '',
      isCorrect: json['correct'] ?? json['isCorrect'] ?? false,
      pointsEarned: json['pointsEarned'] ?? 0,
      phonemeErrors: json['phonemeErrors'] is List
          ? (json['phonemeErrors'] as List).map((e) => e.toString()).toList()
          : const [],
      guidance: (json['guidance'] is String &&
              (json['guidance'] as String).trim().isNotEmpty)
          ? (json['guidance'] as String).trim()
          : null,
    );
  }

  int get stars {
    if (score >= 90) return 3;
    if (score >= 75) return 2;
    if (score >= 60) return 1;
    return 0;
  }
}
