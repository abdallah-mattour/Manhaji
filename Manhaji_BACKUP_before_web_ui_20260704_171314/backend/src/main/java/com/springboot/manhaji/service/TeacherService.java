package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.ClassStudentSummary;
import com.springboot.manhaji.dto.response.LessonSummary;
import com.springboot.manhaji.dto.response.QuestionBankItem;
import com.springboot.manhaji.dto.response.QuestionBankResponse;
import com.springboot.manhaji.dto.response.StudentDetailResponse;
import com.springboot.manhaji.dto.response.SubjectMasterySummary;
import com.springboot.manhaji.dto.response.SubjectSummary;
import com.springboot.manhaji.dto.response.TeacherDashboardResponse;
import com.springboot.manhaji.entity.Attempt;
import com.springboot.manhaji.entity.Progress;
import com.springboot.manhaji.entity.Question;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.Teacher;
import com.springboot.manhaji.entity.TeacherAssignment;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.exception.UnauthorizedException;
import com.springboot.manhaji.repository.AttemptRepository;
import com.springboot.manhaji.repository.ProgressRepository;
import com.springboot.manhaji.repository.QuestionRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import com.springboot.manhaji.repository.TeacherAssignmentRepository;
import com.springboot.manhaji.repository.TeacherRepository;
import com.springboot.manhaji.service.support.ProgressMetrics;
import com.springboot.manhaji.service.support.QuestionBankMapper;
import com.springboot.manhaji.infrastructure.Messages;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TeacherService {

    private final TeacherRepository teacherRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final StudentRepository studentRepository;
    private final ProgressRepository progressRepository;
    private final AttemptRepository attemptRepository;
    private final SubjectRepository subjectRepository;
    private final QuestionRepository questionRepository;
    private final QuestionBankMapper questionBankMapper;
    private final ProgressMetrics metrics;
    private final Messages messages;

    public TeacherDashboardResponse getDashboard(Long teacherId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));

        List<TeacherAssignment> assignments = loadActiveAssignments(teacher);
        List<AssignmentScope> scopes = buildScopes(teacher, assignments);
        List<Student> students = loadStudentsForTeacher(scopes);
        Map<Long, List<Progress>> progressByStudent =
                loadProgressByStudent(students, subjectIdsForScopes(scopes));
        List<ClassStudentSummary> summaries = students.stream()
                .map(s -> buildSummary(
                        s,
                        progressForStudentScope(
                                s,
                                scopes,
                                progressByStudent.getOrDefault(s.getId(), Collections.emptyList()))))
                .sorted(Comparator.comparing(ClassStudentSummary::getTotalPoints,
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .toList();

        LocalDateTime weekAgo = LocalDateTime.now().minusDays(7);
        int activeThisWeek = (int) students.stream()
                .filter(s -> s.getLastLoginAt() != null && s.getLastLoginAt().isAfter(weekAgo))
                .count();

        int lessonsCompletedTotal = summaries.stream()
                .mapToInt(s -> s.getLessonsCompleted() == null ? 0 : s.getLessonsCompleted())
                .sum();

        double avgMastery = summaries.stream()
                .filter(s -> s.getAverageMastery() != null)
                .mapToDouble(ClassStudentSummary::getAverageMastery)
                .average()
                .orElse(0.0);

        List<ClassStudentSummary> topStudents = summaries.stream()
                .limit(5)
                .toList();

        return TeacherDashboardResponse.builder()
                .teacherId(teacher.getId())
                .fullName(teacher.getFullName())
                .department(teacher.getDepartment())
                .assignedGrade(teacher.getAssignedGrade())
                .totalStudents(students.size())
                .activeThisWeek(activeThisWeek)
                .lessonsCompletedTotal(lessonsCompletedTotal)
                .averageMasteryAcrossClass(ProgressMetrics.round2(avgMastery))
                .topStudents(topStudents)
                .build();
    }

    public List<ClassStudentSummary> getStudents(Long teacherId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));
        List<TeacherAssignment> assignments = loadActiveAssignments(teacher);
        List<AssignmentScope> scopes = buildScopes(teacher, assignments);
        List<Student> students = loadStudentsForTeacher(scopes);
        Map<Long, List<Progress>> progressByStudent =
                loadProgressByStudent(students, subjectIdsForScopes(scopes));
        return students.stream()
                .map(s -> buildSummary(
                        s,
                        progressForStudentScope(
                                s,
                                scopes,
                                progressByStudent.getOrDefault(s.getId(), Collections.emptyList()))))
                .sorted(Comparator.comparing(ClassStudentSummary::getFullName,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .toList();
    }

    /**
     * Post-review fix (2026-05-24): the previous code did one
     * {@code progressRepository.findByStudentId} query per student. Now we
     * pull every Progress row for the student set in a single
     * subject-scoped bulk query and group by studentId in memory.
     */
    private Map<Long, List<Progress>> loadProgressByStudent(
            List<Student> students,
            List<Long> subjectIds) {
        if (students.isEmpty() || subjectIds.isEmpty()) return Collections.emptyMap();
        List<Long> ids = students.stream().map(Student::getId).toList();
        return progressRepository.findByStudentIdsAndSubjectIds(ids, subjectIds).stream()
                .collect(Collectors.groupingBy(p -> p.getStudent().getId()));
    }

    public StudentDetailResponse getStudentDetail(Long teacherId, Long studentId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));

        List<TeacherAssignment> assignments = loadActiveAssignments(teacher);
        List<AssignmentScope> studentScopes = scopesForStudent(
                student,
                buildScopes(teacher, assignments));
        if (studentScopes.isEmpty()) {
            throw new UnauthorizedException(messages.get("error.teacher.studentNotAccessible"));
        }

        List<Long> subjectIds = subjectIdsForScopes(studentScopes);
        List<Progress> progressRecords = progressRepository
                .findByStudentIdAndSubjectIds(studentId, subjectIds);
        List<Attempt> attempts = attemptRepository
                .findByStudentIdAndSubjectIdsOrderByCreatedAtDesc(studentId, subjectIds);

        List<SubjectMasterySummary> subjectBreakdown = metrics.buildSubjectBreakdown(
                student,
                progressRecords,
                subjectsForScopes(assignments, studentScopes));

        return StudentDetailResponse.builder()
                .studentId(student.getId())
                .fullName(student.getFullName())
                .email(student.getEmail())
                .phone(student.getPhone())
                .gradeLevel(student.getGradeLevel())
                .totalPoints(student.getTotalPoints())
                .currentStreak(student.getCurrentStreak())
                .lastLoginAt(student.getLastLoginAt())
                .createdAt(student.getCreatedAt())
                .lessonsCompleted(metrics.countCompleted(progressRecords))
                .lessonsInProgress(metrics.countInProgress(progressRecords))
                .overallMastery(ProgressMetrics.round2(metrics.averageMastery(progressRecords)))
                .totalAttempts(attempts.size())
                .averageScore(ProgressMetrics.round2(metrics.averageGradedScore(attempts)))
                .subjectBreakdown(subjectBreakdown)
                .build();
    }

    // ==================== Question Bank (FR-9) ====================

    /**
     * Lists only active subject assignments for this teacher.
     */
    public List<SubjectSummary> getAssignedSubjects(Long teacherId) {
        teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));

        List<Subject> subjects = teacherAssignmentRepository
                .findActiveByTeacherIdWithSubject(teacherId)
                .stream()
                .map(TeacherAssignment::getSubject)
                .toList();

        return subjects.stream()
                .sorted(Comparator.comparing(
                        Subject::getName,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .map(questionBankMapper::toSubjectSummary)
                .toList();
    }

    /**
     * Returns questions belonging to the given subject, filtered by optional
     * difficulty + lesson. Access requires an active teacher-subject assignment.
     */
    public QuestionBankResponse getQuestionsForSubject(
            Long teacherId,
            Long subjectId,
            Integer difficultyLevel,
            Long lessonId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));
        Subject subject = subjectRepository.findById(subjectId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject", subjectId));

        if (!isAssignedSubject(teacher, subject.getId())) {
            throw new UnauthorizedException(messages.get("error.teacher.subjectNotAssigned"));
        }

        List<Question> allForSubject = questionRepository.findAllBySubjectIdWithLesson(subjectId);
        List<LessonSummary> lessons = questionBankMapper.collectLessonFilters(allForSubject);

        List<QuestionBankItem> filtered = allForSubject.stream()
                .filter(q -> difficultyLevel == null
                        || difficultyLevel.equals(q.getDifficultyLevel()))
                .filter(q -> lessonId == null
                        || (q.getLesson() != null && lessonId.equals(q.getLesson().getId())))
                .map(questionBankMapper::toQuestionItem)
                .toList();

        return QuestionBankResponse.builder()
                .subjectId(subject.getId())
                .subjectName(subject.getName())
                .gradeLevel(subject.getGradeLevel())
                .lessons(lessons)
                .questions(filtered)
                .totalQuestionsInSubject(allForSubject.size())
                .build();
    }

    private List<TeacherAssignment> loadActiveAssignments(Teacher teacher) {
        return teacherAssignmentRepository.findActiveByTeacherIdWithSubject(teacher.getId());
    }

    private boolean isAssignedSubject(Teacher teacher, Long subjectId) {
        return loadActiveAssignments(teacher).stream()
                .map(TeacherAssignment::getSubject)
                .anyMatch(subject -> subject != null && subjectId.equals(subject.getId()));
    }

    private List<Student> loadStudentsForTeacher(List<AssignmentScope> scopes) {
        if (scopes.isEmpty()) {
            return Collections.emptyList();
        }

        List<Long> schoolIds = scopes.stream()
                .map(AssignmentScope::schoolId)
                .distinct()
                .toList();
        List<Integer> gradeLevels = scopes.stream()
                .map(AssignmentScope::gradeLevel)
                .distinct()
                .toList();

        Map<Long, Student> visible = new LinkedHashMap<>();
        for (Student student : studentRepository.findBySchoolIdInAndGradeLevelIn(schoolIds, gradeLevels)) {
            if (matchesAnyScope(student, scopes)) {
                visible.putIfAbsent(student.getId(), student);
            }
        }
        return visible.values().stream().toList();
    }

    private List<AssignmentScope> buildScopes(
            Teacher teacher,
            List<TeacherAssignment> assignments) {
        return assignments.stream()
                .map(assignment -> new AssignmentScope(
                        assignment.getGradeLevel(),
                        effectiveSchoolId(teacher, assignment),
                        assignment.getSubject() == null ? null : assignment.getSubject().getId()))
                .filter(AssignmentScope::isUsable)
                .distinct()
                .toList();
    }

    private Long effectiveSchoolId(Teacher teacher, TeacherAssignment assignment) {
        if (assignment.getSchool() != null) {
            return assignment.getSchool().getId();
        }
        return teacher.getSchool() == null ? null : teacher.getSchool().getId();
    }

    private boolean matchesAnyScope(Student student, List<AssignmentScope> scopes) {
        return scopes.stream().anyMatch(scope -> scope.matches(student));
    }

    private List<AssignmentScope> scopesForStudent(
            Student student,
            List<AssignmentScope> scopes) {
        return scopes.stream()
                .filter(scope -> scope.matches(student))
                .toList();
    }

    private List<Long> subjectIdsForScopes(List<AssignmentScope> scopes) {
        return scopes.stream()
                .map(AssignmentScope::subjectId)
                .distinct()
                .toList();
    }

    private List<Progress> progressForStudentScope(
            Student student,
            List<AssignmentScope> scopes,
            List<Progress> progressRecords) {
        Set<Long> subjectIds = new HashSet<>(subjectIdsForScopes(scopesForStudent(student, scopes)));
        return progressRecords.stream()
                .filter(progress -> subjectIds.contains(subjectIdFor(progress)))
                .toList();
    }

    private Long subjectIdFor(Progress progress) {
        if (progress.getLesson() == null || progress.getLesson().getSubject() == null) {
            return null;
        }
        return progress.getLesson().getSubject().getId();
    }

    private List<Subject> subjectsForScopes(
            List<TeacherAssignment> assignments,
            List<AssignmentScope> scopes) {
        Set<Long> subjectIds = new HashSet<>(subjectIdsForScopes(scopes));
        return assignments.stream()
                .map(TeacherAssignment::getSubject)
                .filter(subject -> subject != null && subjectIds.contains(subject.getId()))
                .collect(Collectors.toMap(
                        Subject::getId,
                        subject -> subject,
                        (first, ignored) -> first,
                        LinkedHashMap::new))
                .values()
                .stream()
                .sorted(Comparator.comparing(
                        Subject::getName,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .toList();
    }

    private ClassStudentSummary buildSummary(Student student, List<Progress> progressRecords) {
        return ClassStudentSummary.builder()
                .studentId(student.getId())
                .fullName(student.getFullName())
                .email(student.getEmail())
                .gradeLevel(student.getGradeLevel())
                .totalPoints(student.getTotalPoints())
                .currentStreak(student.getCurrentStreak())
                .lessonsCompleted(metrics.countCompleted(progressRecords))
                .lessonsInProgress(metrics.countInProgress(progressRecords))
                .averageMastery(ProgressMetrics.round2(metrics.averageMastery(progressRecords)))
                .lastLoginAt(student.getLastLoginAt())
                .build();
    }

    private record AssignmentScope(Integer gradeLevel, Long schoolId, Long subjectId) {
        boolean isUsable() {
            return gradeLevel != null && schoolId != null && subjectId != null;
        }

        boolean matches(Student student) {
            Long studentSchoolId = student.getSchool() == null ? null : student.getSchool().getId();
            return gradeLevel.equals(student.getGradeLevel())
                    && schoolId.equals(studentSchoolId);
        }
    }
}
