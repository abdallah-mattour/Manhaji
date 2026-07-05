int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

int? _asOptionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String _asString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

String? _asOptionalString(dynamic value) {
  final text = _asString(value).trim();
  return text.isEmpty ? null : text;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) return value.trim().toLowerCase() == 'true';
  return false;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

class TeacherMistakeAnalytics {
  final TeacherMistakeSummary summary;
  final List<TeacherMistakeRow> mistakes;

  const TeacherMistakeAnalytics({
    required this.summary,
    required this.mistakes,
  });

  factory TeacherMistakeAnalytics.fromJson(Map<String, dynamic> json) {
    final mistakes = json['mistakes'] as List? ?? const [];
    return TeacherMistakeAnalytics(
      summary: TeacherMistakeSummary.fromJson(_asMap(json['summary'])),
      mistakes: mistakes
          .map((row) => TeacherMistakeRow.fromJson(_asMap(row)))
          .toList(),
    );
  }
}

class TeacherMistakeSummary {
  final int totalMistakes;
  final int affectedStudents;
  final int? mostMistakenLessonId;
  final String? mostMistakenLessonTitle;
  final int? mostMistakenQuestionId;
  final String? mostMistakenQuestionText;

  const TeacherMistakeSummary({
    required this.totalMistakes,
    required this.affectedStudents,
    this.mostMistakenLessonId,
    this.mostMistakenLessonTitle,
    this.mostMistakenQuestionId,
    this.mostMistakenQuestionText,
  });

  factory TeacherMistakeSummary.fromJson(Map<String, dynamic> json) {
    return TeacherMistakeSummary(
      totalMistakes: _asInt(json['totalMistakes']),
      affectedStudents: _asInt(json['affectedStudents']),
      mostMistakenLessonId: _asOptionalInt(json['mostMistakenLessonId']),
      mostMistakenLessonTitle: _asOptionalString(
        json['mostMistakenLessonTitle'],
      ),
      mostMistakenQuestionId: _asOptionalInt(json['mostMistakenQuestionId']),
      mostMistakenQuestionText: _asOptionalString(
        json['mostMistakenQuestionText'],
      ),
    );
  }
}

class TeacherMistakeRow {
  final int studentId;
  final String studentName;
  final int subjectId;
  final String subjectName;
  final int lessonId;
  final String lessonTitle;
  final int questionId;
  final String questionText;
  final String? studentAnswer;
  final String? correctAnswer;
  final int mistakeCount;
  final String? lastMistakeAt;
  final bool commonMistake;
  final int affectedStudentsForQuestion;

  const TeacherMistakeRow({
    required this.studentId,
    required this.studentName,
    required this.subjectId,
    required this.subjectName,
    required this.lessonId,
    required this.lessonTitle,
    required this.questionId,
    required this.questionText,
    this.studentAnswer,
    this.correctAnswer,
    required this.mistakeCount,
    this.lastMistakeAt,
    required this.commonMistake,
    required this.affectedStudentsForQuestion,
  });

  factory TeacherMistakeRow.fromJson(Map<String, dynamic> json) {
    return TeacherMistakeRow(
      studentId: _asInt(json['studentId']),
      studentName: _asString(json['studentName']),
      subjectId: _asInt(json['subjectId']),
      subjectName: _asString(json['subjectName']),
      lessonId: _asInt(json['lessonId']),
      lessonTitle: _asString(json['lessonTitle']),
      questionId: _asInt(json['questionId']),
      questionText: _asString(json['questionText']),
      studentAnswer: _asOptionalString(json['studentAnswer']),
      correctAnswer: _asOptionalString(json['correctAnswer']),
      mistakeCount: _asInt(json['mistakeCount']),
      lastMistakeAt: _asOptionalString(json['lastMistakeAt']),
      commonMistake: _asBool(json['commonMistake']),
      affectedStudentsForQuestion: _asInt(json['affectedStudentsForQuestion']),
    );
  }
}
