class Quiz {
  final int id;
  final String title;
  final bool gamified;
  final int totalQuestions;
  final List<Question> questions;
  final String? lessonContent;
  final String? lessonObjectives;

  Quiz({
    required this.id,
    required this.title,
    required this.gamified,
    required this.totalQuestions,
    required this.questions,
    this.lessonContent,
    this.lessonObjectives,
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
    );
  }
}

class Question {
  final int id;
  final String type; // MCQ, TRUE_FALSE, SHORT_ANSWER
  final String questionText;
  final List<String>? options;
  final int difficultyLevel;

  Question({
    required this.id,
    required this.type,
    required this.questionText,
    this.options,
    required this.difficultyLevel,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'MCQ',
      questionText: json['questionText'] ?? '',
      options: json['options'] is List
          ? (json['options'] as List).map((e) => e.toString()).toList()
          : null,
      difficultyLevel: json['difficultyLevel'] ?? 1,
    );
  }

  bool get isMCQ => type == 'MCQ';
  bool get isTrueFalse => type == 'TRUE_FALSE';
  bool get isShortAnswer => type == 'SHORT_ANSWER';
  bool get isFillBlank => type == 'FILL_BLANK';
  bool get isOrdering => type == 'ORDERING';
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
