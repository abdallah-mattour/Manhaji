class Subject {
  final int id;
  final String name;
  final int gradeLevel;
  final int totalLessons;
  final int completedLessons;

  /// Optional cover-image URL. Null until the backend provides one; the
  /// subject card falls back to a colored icon bubble when absent. Lets the
  /// card become image-ready with zero backend change today.
  final String? coverImage;

  Subject({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.totalLessons,
    required this.completedLessons,
    this.coverImage,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      gradeLevel: json['gradeLevel'] ?? 1,
      totalLessons: json['totalLessons'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
      coverImage: json['coverImage'] as String?,
    );
  }

  double get progressPercent =>
      totalLessons > 0 ? completedLessons / totalLessons : 0.0;
}
