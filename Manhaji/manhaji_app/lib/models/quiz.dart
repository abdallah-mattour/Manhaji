class Quiz {
  final int id;
  final String title;
  final bool gamified;
  final int totalQuestions;
  final List<Question> questions;
  final String? lessonContent;
  final String? lessonObjectives;
  final List<String> lessonImageUrls;

  Quiz({
    required this.id,
    required this.title,
    required this.gamified,
    required this.totalQuestions,
    required this.questions,
    this.lessonContent,
    this.lessonObjectives,
    this.lessonImageUrls = const [],
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      gamified: json['gamified'] ?? false,
      totalQuestions: json['totalQuestions'] ?? 0,
      questions: (json['questions'] as List?)
              ?.map((q) => Question.fromJson(q))
              .toList() ??
          [],
      lessonContent: json['lessonContent'],
      lessonObjectives: json['lessonObjectives'],
      lessonImageUrls: json['lessonImageUrls'] is List
          ? (json['lessonImageUrls'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }
}

class Question {
  final int id;
  final String type; // MCQ, TRUE_FALSE, SHORT_ANSWER, FILL_BLANK, ORDERING, PRONUNCIATION, TRACING
  final String questionText;
  final List<String>? options;
  final int difficultyLevel;

  /// Sub-skill tag (recognition / production / pronunciation / handwriting / ...).
  /// Drives mastery analytics. Null when the backend hasn't tagged the row;
  /// the home/progress UI falls back to deriving from [type].
  final String? subSkill;

  /// Optional image asset path served by the backend at e.g.
  /// `/assets/questions/ar/letters/ra/remmaan.png`. Rendered above the prompt.
  final String? imageUrl;

  /// Optional audio asset path. Used for English pronunciation playback and
  /// Religion Surah recitation playback.
  final String? audioUrl;

  /// Tier 1: image path per option, parallel to [options], for IMAGE_MCQ /
  /// LISTEN_CHOOSE. An entry may be null/empty — the widget then shows the
  /// option text instead, so a question works even before images ship.
  final List<String?>? optionImages;

  /// Tier 1: IMAGE_MATCH data — `{left:[{id,text,image}], right:[{id,text,image}]}`.
  /// Null for non-match questions.
  final Map<String, dynamic>? pairs;

  Question({
    required this.id,
    required this.type,
    required this.questionText,
    this.options,
    required this.difficultyLevel,
    this.subSkill,
    this.imageUrl,
    this.audioUrl,
    this.optionImages,
    this.pairs,
  });

  /// Tier 2: tolerant type parsing. Normalizes casing/hyphens and maps known
  /// aliases (e.g. from hand-authored JSON or a differently-named backend
  /// enum) onto our canonical type strings, so a near-miss renders the right
  /// widget instead of silently falling through to the short-answer text box.
  static String normalizeType(dynamic raw) {
    final t = (raw?.toString() ?? 'MCQ')
        .trim()
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    switch (t) {
      case 'MULTIPLE_CHOICE':
        return 'MCQ';
      case 'DRAGDROP':
      case 'DRAG_AND_DROP':
        return 'DRAG_DROP';
      case 'LISTEN_AND_CHOOSE':
        return 'LISTEN_CHOOSE';
      case 'REORDER_WORDS':
      case 'REORDER':
        return 'ORDERING';
      case 'VOICE_ANSWER':
        return 'PRONUNCIATION';
      case 'WRITE_ANSWER':
        return 'SHORT_ANSWER';
      default:
        return t.isEmpty ? 'MCQ' : t;
    }
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? 0,
      type: normalizeType(json['type']),
      questionText: json['questionText'] ?? '',
      options: json['options'] is List
          ? (json['options'] as List).map((e) => e.toString()).toList()
          : null,
      difficultyLevel: json['difficultyLevel'] ?? 1,
      subSkill: json['subSkill']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      audioUrl: json['audioUrl']?.toString(),
      optionImages: json['optionImages'] is List
          ? (json['optionImages'] as List)
              .map((e) => e?.toString())
              .toList()
          : null,
      pairs: json['pairsJson'] is Map
          ? Map<String, dynamic>.from(json['pairsJson'] as Map)
          : null,
    );
  }

  bool get isMCQ => type == 'MCQ';
  bool get isTrueFalse => type == 'TRUE_FALSE';
  bool get isShortAnswer => type == 'SHORT_ANSWER';
  bool get isFillBlank => type == 'FILL_BLANK';
  bool get isOrdering => type == 'ORDERING';
  bool get isPronunciation => type == 'PRONUNCIATION';
  bool get isTracing => type == 'TRACING';
  // Tier 1 interactive types.
  bool get isImageMcq => type == 'IMAGE_MCQ';
  bool get isListenChoose => type == 'LISTEN_CHOOSE';
  bool get isImageMatch => type == 'IMAGE_MATCH';
  // Tier 2: drag tokens into named target groups (data in [pairs] as
  // {targets:[...], tokens:[...]}; submits "target=token,..." like a match).
  bool get isDragDrop => type == 'DRAG_DROP';
  // Tier 4: read-aloud passage ([questionText] is the passage) scored
  // word-by-word through the pronunciation endpoint.
  bool get isReading => type == 'READING';
}

class AttemptResult {
  final int attemptId;
  final int quizId;
  final String status;
  final double? score;
  final int totalQuestions;
  final int correctAnswers;
  final int pointsEarned;
  final List<AnswerFeedback> answers;

  AttemptResult({
    required this.attemptId,
    required this.quizId,
    required this.status,
    this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.pointsEarned,
    required this.answers,
  });

  factory AttemptResult.fromJson(Map<String, dynamic> json) {
    return AttemptResult(
      attemptId: json['attemptId'] ?? 0,
      quizId: json['quizId'] ?? 0,
      status: json['status'] ?? '',
      score: json['score']?.toDouble(),
      totalQuestions: json['totalQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      pointsEarned: json['pointsEarned'] ?? 0,
      answers: (json['answers'] as List?)
              ?.map((a) => AnswerFeedback.fromJson(a))
              .toList() ??
          [],
    );
  }

  double get scorePercent => score ?? 0;
  bool get isPassed => scorePercent >= 50;
  bool get isMastered => scorePercent >= 80;
}

class AnswerFeedback {
  final int questionId;
  final String questionText;
  final String? studentAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String? feedback;

  AnswerFeedback({
    required this.questionId,
    required this.questionText,
    this.studentAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.feedback,
  });

  factory AnswerFeedback.fromJson(Map<String, dynamic> json) {
    return AnswerFeedback(
      questionId: json['questionId'] ?? 0,
      questionText: json['questionText'] ?? '',
      studentAnswer: json['studentAnswer'],
      correctAnswer: json['correctAnswer'] ?? '',
      isCorrect: json['correct'] ?? false,
      feedback: json['feedback'],
    );
  }
}

class SubmitAnswerResult {
  final int questionId;
  final bool isCorrect;
  final String? feedback;
  final String correctAnswer;
  final int pointsEarned;

  SubmitAnswerResult({
    required this.questionId,
    required this.isCorrect,
    this.feedback,
    required this.correctAnswer,
    required this.pointsEarned,
  });

  factory SubmitAnswerResult.fromJson(Map<String, dynamic> json) {
    return SubmitAnswerResult(
      questionId: json['questionId'] ?? 0,
      isCorrect: json['correct'] ?? false,
      feedback: json['feedback'],
      correctAnswer: json['correctAnswer'] ?? '',
      pointsEarned: json['pointsEarned'] ?? 0,
    );
  }
}
