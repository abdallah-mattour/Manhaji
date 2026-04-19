class PronunciationScore {
  final int questionId;
  final String expectedText;
  final String transcribedText;
  final int score;
  final String rating;
  final String feedback;
  final bool isCorrect;
  final int pointsEarned;

  PronunciationScore({
    required this.questionId,
    required this.expectedText,
    required this.transcribedText,
    required this.score,
    required this.rating,
    required this.feedback,
    required this.isCorrect,
    required this.pointsEarned,
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
    );
  }

  int get stars {
    if (score >= 90) return 3;
    if (score >= 75) return 2;
    if (score >= 60) return 1;
    return 0;
  }
}
