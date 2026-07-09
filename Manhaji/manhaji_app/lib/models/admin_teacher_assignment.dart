class TeacherAssignmentPayload {
  const TeacherAssignmentPayload({
    required this.subjectId,
    this.gradeLevel,
    this.schoolId,
  });

  final int subjectId;
  final int? gradeLevel;
  final int? schoolId;

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      if (gradeLevel != null) 'gradeLevel': gradeLevel,
      if (schoolId != null) 'schoolId': schoolId,
    };
  }
}

class AdminTeacherAssignment {
  const AdminTeacherAssignment({
    required this.id,
    required this.teacherId,
    required this.subjectId,
    required this.subjectName,
    required this.gradeLevel,
    this.schoolId,
    this.schoolName,
    required this.isActive,
    this.createdAt,
  });

  final int id;
  final int teacherId;
  final int subjectId;
  final String subjectName;
  final int gradeLevel;
  final int? schoolId;
  final String? schoolName;
  final bool isActive;
  final String? createdAt;

  factory AdminTeacherAssignment.fromJson(Map<String, dynamic> json) {
    return AdminTeacherAssignment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      teacherId: (json['teacherId'] as num?)?.toInt() ?? 0,
      subjectId: (json['subjectId'] as num?)?.toInt() ?? 0,
      subjectName:
          json['subjectName']?.toString() ??
          json['subjectNameArabic']?.toString() ??
          json['name']?.toString() ??
          '',
      gradeLevel: (json['gradeLevel'] as num?)?.toInt() ?? 0,
      schoolId: (json['schoolId'] as num?)?.toInt(),
      schoolName: json['schoolName']?.toString(),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      createdAt: json['createdAt']?.toString(),
    );
  }

  TeacherAssignmentPayload toPayload() {
    return TeacherAssignmentPayload(
      subjectId: subjectId,
      gradeLevel: gradeLevel == 0 ? null : gradeLevel,
      schoolId: schoolId,
    );
  }
}
