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
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.exception.UnauthorizedException;
import com.springboot.manhaji.repository.AttemptRepository;
import com.springboot.manhaji.repository.ProgressRepository;
import com.springboot.manhaji.repository.QuestionRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import com.springboot.manhaji.repository.TeacherRepository;
import com.springboot.manhaji.service.support.ProgressMetrics;
import com.springboot.manhaji.service.support.QuestionBankMapper;
import com.springboot.manhaji.support.Messages;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TeacherService {

    private final TeacherRepository teacherRepository;
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

        List<Student> students = loadStudentsForTeacher(teacher);
        List<ClassStudentSummary> summaries = students.stream()
                .map(this::buildSummary)
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
        return loadStudentsForTeacher(teacher).stream()
                .map(this::buildSummary)
                .sorted(Comparator.comparing(ClassStudentSummary::getFullName,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .toList();
    }

    public StudentDetailResponse getStudentDetail(Long teacherId, Long studentId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));

        if (!isStudentVisibleToTeacher(student, teacher)) {
            throw new UnauthorizedException(messages.get("error.teacher.studentNotAccessible"));
        }

        List<Progress> progressRecords = progressRepository.findByStudentId(studentId);
        List<Attempt> attempts = attemptRepository.findByStudentIdOrderByCreatedAtDesc(studentId);

        List<SubjectMasterySummary> subjectBreakdown = metrics.buildSubjectBreakdown(student, progressRecords);

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
     * Lists all subjects at the teacher's assigned grade. When the teacher has
     * no grade set, falls back to every subject so the demo still shows rows.
     */
    public List<SubjectSummary> getAssignedSubjects(Long teacherId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));

        List<Subject> subjects = teacher.getAssignedGrade() != null
                ? subjectRepository.findByGradeLevel(teacher.getAssignedGrade())
                : subjectRepository.findAll();

        return subjects.stream()
                .sorted(Comparator.comparing(
                        Subject::getName,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .map(questionBankMapper::toSubjectSummary)
                .toList();
    }

    /**
     * Returns questions belonging to the given subject, filtered by optional
     * difficulty + lesson. Access is denied if the subject is at a grade other
     * than the teacher's {@code assignedGrade} (teachers with no grade assigned
     * can see everything — matches {@link #loadStudentsForTeacher}).
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

        if (teacher.getAssignedGrade() != null
                && !teacher.getAssignedGrade().equals(subject.getGradeLevel())) {
            throw new UnauthorizedException(messages.get("error.teacher.subjectNotInGrade"));
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

    /**
     * A teacher sees students that match their assigned grade, or all students at
     * the teacher's school when grade is unset. This is intentionally permissive
     * so demos with sparse seed data still display rows.
     */
    private List<Student> loadStudentsForTeacher(Teacher teacher) {
        List<Student> students = new ArrayList<>();
        Long schoolId = teacher.getSchool() != null ? teacher.getSchool().getId() : null;
        Integer grade = teacher.getAssignedGrade();

        if (schoolId != null && grade != null) {
            students.addAll(studentRepository.findBySchoolIdAndGradeLevel(schoolId, grade));
        } else if (schoolId != null) {
            students.addAll(studentRepository.findBySchoolId(schoolId));
        } else if (grade != null) {
            students.addAll(studentRepository.findByGradeLevel(grade));
        } else {
            students.addAll(studentRepository.findAll());
        }
        return students;
    }

    private boolean isStudentVisibleToTeacher(Student student, Teacher teacher) {
        Long schoolId = teacher.getSchool() != null ? teacher.getSchool().getId() : null;
        Integer grade = teacher.getAssignedGrade();
        Long studentSchoolId = student.getSchool() != null ? student.getSchool().getId() : null;

        if (schoolId == null && grade == null) {
            return true;
        }
        if (grade != null && !grade.equals(student.getGradeLevel())) {
            return false;
        }
        if (schoolId != null && !schoolId.equals(studentSchoolId)) {
            return false;
        }
        return true;
    }

    private ClassStudentSummary buildSummary(Student student) {
        List<Progress> progressRecords = progressRepository.findByStudentId(student.getId());
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
}
