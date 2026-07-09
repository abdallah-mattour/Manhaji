import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/admin_teacher_assignment.dart';

void main() {
  group('AdminTeacherAssignment', () {
    test('fromJson parses backend response safely', () {
      final assignment = AdminTeacherAssignment.fromJson({
        'id': 11,
        'teacherId': 7,
        'subjectId': 5,
        'subjectName': 'الرياضيات',
        'gradeLevel': 2,
        'schoolId': 3,
        'schoolName': 'مدرسة demo',
        'isActive': true,
        'createdAt': '2026-07-04T10:15:00',
      });

      expect(assignment.id, 11);
      expect(assignment.teacherId, 7);
      expect(assignment.subjectId, 5);
      expect(assignment.subjectName, 'الرياضيات');
      expect(assignment.gradeLevel, 2);
      expect(assignment.schoolId, 3);
      expect(assignment.schoolName, 'مدرسة demo');
      expect(assignment.isActive, true);
      expect(assignment.createdAt, '2026-07-04T10:15:00');
    });

    test('payload serializes create and replace contract', () {
      const payload = TeacherAssignmentPayload(subjectId: 5, gradeLevel: 2);

      expect(payload.toJson(), {'subjectId': 5, 'gradeLevel': 2});
    });
  });
}
