class Subject {
  final int id;
  final String name;
  final int gradeLevel;
  final int totalLessons;
  final int completedLessons;

  Subject({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.totalLessons,
    required this.completedLessons,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      gradeLevel: json['gradeLevel'] ?? 1,
      totalLessons: json['totalLessons'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
    );
  }

  double get progressPercent =>
      totalLessons > 0 ? completedLessons / totalLessons : 0.0;
}
