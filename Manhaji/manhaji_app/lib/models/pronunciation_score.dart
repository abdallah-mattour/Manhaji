/// Tier 4 (2026-07): one READING passage word + whether it was read correctly.
class WordScore {
  final String word;
  final bool correct;

  const WordScore({required this.word, required this.correct});

  factory WordScore.fromJson(Map<String, dynamic> json) => WordScore(
        word: json['word']?.toString() ?? '',
        correct: json['correct'] == true,
      );
}

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

  /// Tier 4 (2026-07): READING questions only — per passage word, in passage
  /// order, so the reading widget can color the text. Empty otherwise.
  final List<WordScore> wordResults;

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
    this.wordResults = const [],
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
      wordResults: json['wordResults'] is List
          ? (json['wordResults'] as List)
              .whereType<Map>()
              .map((e) => WordScore.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  int get stars {
    if (score >= 90) return 3;
    if (score >= 75) return 2;
    if (score >= 60) return 1;
    return 0;
  }

  /// Child-safe transcript: empty when the backend leaked something technical
  /// (raw/truncated JSON, code fences) instead of plain speech text, so the
  /// "ما سمعناه" box simply hides rather than showing gibberish to a child.
  String get displayTranscribed {
    final t = transcribedText.trim();
    if (t.isEmpty) return '';
    if (t.contains('{') ||
        t.contains('}') ||
        t.contains('```') ||
        t.contains('"transcribed"') ||
        t.contains('phonemeErrors')) {
      return '';
    }
    return t;
  }
}
