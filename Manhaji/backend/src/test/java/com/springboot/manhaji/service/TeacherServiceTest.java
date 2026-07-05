package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.ClassStudentSummary;
import com.springboot.manhaji.dto.response.QuestionBankResponse;
import com.springboot.manhaji.dto.response.StudentDetailResponse;
import com.springboot.manhaji.dto.response.SubjectSummary;
import com.springboot.manhaji.dto.response.TeacherDashboardResponse;
import com.springboot.manhaji.dto.response.TeacherMistakeAnalyticsResponse;
import com.springboot.manhaji.entity.*;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.exception.UnauthorizedException;
import com.springboot.manhaji.repository.*;
import com.springboot.manhaji.service.support.ProgressMetrics;
import com.springboot.manhaji.service.support.QuestionBankMapper;
import com.springboot.manhaji.infrastructure.TestMessages;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TeacherServiceTest {

    @Mock private TeacherRepository teacherRepository;
    @Mock private TeacherAssignmentRepository teacherAssignmentRepository;
    @Mock private StudentRepository studentRepository;
    @Mock private ProgressRepository progressRepository;
    @Mock private AttemptRepository attemptRepository;
    @Mock private StudentResponseRepository studentResponseRepository;
    @Mock private SubjectRepository subjectRepository;
    @Mock private LessonRepository lessonRepository;
    @Mock private QuestionRepository questionRepository;

    private TeacherService teacherService;

    private Teacher teacher;
    private School school;
    private Student student1;
    private Student student2;

    @BeforeEach
    void setUp() {
        ProgressMetrics metrics = new ProgressMetrics(subjectRepository, lessonRepository);
        QuestionBankMapper questionBankMapper = new QuestionBankMapper();
        teacherService = new TeacherService(
                teacherRepository, teacherAssignmentRepository,
                studentRepository, progressRepository, attemptRepository,
                studentResponseRepository, subjectRepository, questionRepository, questionBankMapper,
                metrics, TestMessages.create());

        school = new School();
        school.setId(7L);
        school.setName("مدرسة منهاجي");

        teacher = new Teacher();
        teacher.setId(10L);
        teacher.setFullName("أستاذ أحمد");
        teacher.setDepartment("اللغة العربية");
        teacher.setAssignedGrade(1);
        teacher.setSchool(school);
        teacher.setRole(Role.TEACHER);

        student1 = new Student();
        student1.setId(1L);
        student1.setFullName("طالب واحد");
        student1.setEmail("s1@test.com");
        student1.setGradeLevel(1);
        student1.setSchool(school);
        student1.setTotalPoints(100);
        student1.setCurrentStreak(3);
        student1.setLastLoginAt(LocalDateTime.now().minusDays(1));

        student2 = new Student();
        student2.setId(2L);
        student2.setFullName("طالب اثنان");
        student2.setEmail("s2@test.com");
        student2.setGradeLevel(1);
        student2.setSchool(school);
        student2.setTotalPoints(50);
        student2.setCurrentStreak(1);
        student2.setLastLoginAt(LocalDateTime.now().minusDays(10));
    }

    // ==================== getDashboard Tests ====================

    @Nested
    @DisplayName("getDashboard()")
    class GetDashboardTests {

        @Test
        @DisplayName("Arabic teacher dashboard uses Arabic progress only")
        void arabicTeacherDashboardUsesArabicProgressOnly() {
            Subject arabic = createSubject(100L, "Arabic", 1);
            Lesson arabicLesson = createLesson(200L, arabic, "Arabic Lesson", 1);
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(1L, arabic)));
            when(studentRepository.findBySchoolIdInAndGradeLevelIn(List.of(7L), List.of(1)))
                    .thenReturn(List.of(student1, student2));
            when(progressRepository.findByStudentIdsAndSubjectIds(
                    List.of(1L, 2L), List.of(100L))).thenReturn(List.of(
                    createProgressFor(student1, arabicLesson, CompletionStatus.COMPLETED, 85.0),
                    createProgressFor(student2, arabicLesson, CompletionStatus.IN_PROGRESS, 55.0)
            ));

            TeacherDashboardResponse response = teacherService.getDashboard(10L);

            assertThat(response.getTeacherId()).isEqualTo(10L);
            assertThat(response.getFullName()).isEqualTo("أستاذ أحمد");
            assertThat(response.getTotalStudents()).isEqualTo(2);
            assertThat(response.getActiveThisWeek()).isEqualTo(1); // Only student1 logged in within 7 days
            assertThat(response.getLessonsCompletedTotal()).isEqualTo(1);
            assertThat(response.getAverageMasteryAcrossClass()).isEqualTo(70.0);
            assertThat(response.getTopStudents()).hasSizeLessThanOrEqualTo(5);
        }

        @Test
        @DisplayName("Islamic teacher dashboard uses Islamic progress only")
        void islamicTeacherDashboardUsesIslamicProgressOnly() {
            Subject islamic = createSubject(101L, "Islamic", 1);
            Lesson islamicLesson = createLesson(201L, islamic, "Islamic Lesson", 1);
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(2L, islamic)));
            when(studentRepository.findBySchoolIdInAndGradeLevelIn(List.of(7L), List.of(1)))
                    .thenReturn(List.of(student1, student2));
            when(progressRepository.findByStudentIdsAndSubjectIds(
                    List.of(1L, 2L), List.of(101L))).thenReturn(List.of(
                    createProgressFor(student1, islamicLesson, CompletionStatus.COMPLETED, 92.0)
            ));

            TeacherDashboardResponse response = teacherService.getDashboard(10L);

            assertThat(response.getTotalStudents()).isEqualTo(2);
            assertThat(response.getLessonsCompletedTotal()).isEqualTo(1);
            assertThat(response.getAverageMasteryAcrossClass()).isEqualTo(46.0);
            verify(progressRepository).findByStudentIdsAndSubjectIds(
                    List.of(1L, 2L), List.of(101L));
        }

        @Test
        @DisplayName("should throw when teacher not found")
        void teacherNotFound() {
            when(teacherRepository.findById(999L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> teacherService.getDashboard(999L))
                    .isInstanceOf(ResourceNotFoundException.class);
        }

        @Test
        @DisplayName("should return no students when no grade/school")
        void noFallbackWhenNoGradeOrSchool() {
            Teacher unassigned = new Teacher();
            unassigned.setId(20L);
            unassigned.setFullName("أستاذ بدون تعيين");
            // No school, no grade

            when(teacherRepository.findById(20L)).thenReturn(Optional.of(unassigned));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(20L))
                    .thenReturn(List.of());

            TeacherDashboardResponse response = teacherService.getDashboard(20L);

            assertThat(response.getTotalStudents()).isZero();
            assertThat(response.getActiveThisWeek()).isZero();
            assertThat(response.getLessonsCompletedTotal()).isZero();
            assertThat(response.getAverageMasteryAcrossClass()).isZero();
            assertThat(response.getTopStudents()).isEmpty();
            verifyNoInteractions(studentRepository);
        }
    }

    // ==================== getStudents Tests ====================

    @Nested
    @DisplayName("getStudents()")
    class GetStudentsTests {

        @Test
        @DisplayName("students list excludes students outside assignment grade/school scope")
        void studentsListExcludesStudentsOutsideAssignmentScope() {
            Subject arabic = createSubject(100L, "Arabic", 1);
            Lesson arabicLesson = createLesson(200L, arabic, "Arabic Lesson", 1);
            School otherSchool = new School();
            otherSchool.setId(8L);
            Student outsideScope = new Student();
            outsideScope.setId(3L);
            outsideScope.setFullName("طالب خارج النطاق");
            outsideScope.setEmail("s3@test.com");
            outsideScope.setGradeLevel(1);
            outsideScope.setSchool(otherSchool);
            outsideScope.setTotalPoints(500);
            outsideScope.setCurrentStreak(8);

            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(1L, arabic)));
            when(studentRepository.findBySchoolIdInAndGradeLevelIn(List.of(7L), List.of(1)))
                    .thenReturn(List.of(student1, student2, outsideScope));
            when(progressRepository.findByStudentIdsAndSubjectIds(
                    List.of(1L, 2L), List.of(100L))).thenReturn(List.of(
                    createProgressFor(student1, arabicLesson, CompletionStatus.COMPLETED, 80.0)
            ));

            List<ClassStudentSummary> students = teacherService.getStudents(10L);

            assertThat(students).hasSize(2);
            assertThat(students).extracting(ClassStudentSummary::getStudentId)
                    .containsExactly(2L, 1L);
            assertThat(students).extracting(ClassStudentSummary::getStudentId)
                    .doesNotContain(3L);
            // Sorted by name alphabetically
            assertThat(students.get(0).getFullName()).isEqualTo("طالب اثنان");
            assertThat(students.get(1).getFullName()).isEqualTo("طالب واحد");
        }

        @Test
        @DisplayName("teacher with no assignments gets empty student list")
        void teacherWithNoAssignmentsGetsEmptyStudentList() {
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of());

            List<ClassStudentSummary> students = teacherService.getStudents(10L);

            assertThat(students).isEmpty();
            verifyNoInteractions(studentRepository);
        }
    }

    // ==================== getStudentDetail Tests ====================

    @Nested
    @DisplayName("getStudentDetail()")
    class GetStudentDetailTests {

        @Test
        @DisplayName("student detail returns only assigned subject breakdown")
        void studentDetailReturnsOnlyAssignedSubjectBreakdown() {
            Subject arabic = createSubject(100L, "Arabic", 1);
            Subject islamic = createSubject(101L, "Islamic", 1);
            Lesson arabicLesson = createLesson(200L, arabic, "Arabic Lesson", 1);
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(studentRepository.findById(1L)).thenReturn(Optional.of(student1));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(1L, arabic)));
            when(progressRepository.findByStudentIdAndSubjectIds(1L, List.of(100L))).thenReturn(List.of(
                    createProgressFor(student1, arabicLesson, CompletionStatus.COMPLETED, 90.0)
            ));
            when(attemptRepository.findByStudentIdAndSubjectIdsOrderByCreatedAtDesc(1L, List.of(100L)))
                    .thenReturn(List.of(
                    createAttempt(AttemptStatus.GRADED, 85.0)
            ));
            when(lessonRepository.findBySubjectIdsAndGradeLevel(List.of(100L), 1))
                    .thenReturn(List.of(arabicLesson));

            StudentDetailResponse detail = teacherService.getStudentDetail(10L, 1L);

            assertThat(detail.getStudentId()).isEqualTo(1L);
            assertThat(detail.getFullName()).isEqualTo("طالب واحد");
            assertThat(detail.getLessonsCompleted()).isEqualTo(1);
            assertThat(detail.getTotalAttempts()).isEqualTo(1);
            assertThat(detail.getAverageScore()).isEqualTo(85.0);
            assertThat(detail.getSubjectBreakdown()).hasSize(1);
            assertThat(detail.getSubjectBreakdown().get(0).getSubjectName()).isEqualTo("Arabic");
            assertThat(detail.getSubjectBreakdown())
                    .extracting("subjectName")
                    .doesNotContain(islamic.getName());
            verify(progressRepository).findByStudentIdAndSubjectIds(1L, List.of(100L));
            verify(attemptRepository).findByStudentIdAndSubjectIdsOrderByCreatedAtDesc(1L, List.of(100L));
        }

        @Test
        @DisplayName("should deny access when student grade doesn't match teacher")
        void denyAccessWrongGrade() {
            Subject arabic = createSubject(100L, "Arabic", 1);
            Student grade2Student = new Student();
            grade2Student.setId(3L);
            grade2Student.setGradeLevel(2); // Teacher is assigned grade 1
            grade2Student.setSchool(school);

            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(studentRepository.findById(3L)).thenReturn(Optional.of(grade2Student));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(1L, arabic)));

            assertThatThrownBy(() -> teacherService.getStudentDetail(10L, 3L))
                    .isInstanceOf(UnauthorizedException.class);
            verifyNoInteractions(progressRepository);
        }
    }

    // ==================== Mistake Analytics Tests ====================

    @Nested
    @DisplayName("getMistakeAnalytics()")
    class GetMistakeAnalyticsTests {

        @Test
        @DisplayName("teacher sees only mistakes in assigned subject")
        void teacherSeesOnlyAssignedSubjectMistakes() {
            Subject arabic = createSubject(100L, "Arabic", 1);
            Subject math = createSubject(300L, "Math", 1);
            Lesson arabicLesson = createLesson(200L, arabic, "Arabic Lesson", 1);
            Lesson mathLesson = createLesson(300L, math, "Math Lesson", 1);
            Question arabicQuestion = createQuestion(500L, arabicLesson, "Arabic Q", 1);
            Question mathQuestion = createQuestion(700L, mathLesson, "Math Q", 1);
            StudentResponse firstArabicMistake = createMistakeResponse(
                    1L, student1, arabicQuestion, "B", LocalDateTime.now().minusDays(2));
            StudentResponse secondArabicMistake = createMistakeResponse(
                    2L, student2, arabicQuestion, "C", LocalDateTime.now().minusDays(1));
            StudentResponse leakedMathMistake = createMistakeResponse(
                    3L, student1, mathQuestion, "9", LocalDateTime.now());

            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(1L, arabic)));
            when(studentRepository.findBySchoolIdInAndGradeLevelIn(List.of(7L), List.of(1)))
                    .thenReturn(List.of(student1, student2));
            when(studentResponseRepository.findIncorrectByStudentIdsAndSubjectIds(
                    List.of(1L, 2L), List.of(100L), null, null, null))
                    .thenReturn(List.of(firstArabicMistake, secondArabicMistake, leakedMathMistake));

            TeacherMistakeAnalyticsResponse response = teacherService
                    .getMistakeAnalytics(10L, null, null, null, null);

            assertThat(response.getSummary().getTotalMistakes()).isEqualTo(2);
            assertThat(response.getSummary().getAffectedStudents()).isEqualTo(2);
            assertThat(response.getSummary().getMostMistakenLessonTitle()).isEqualTo("Arabic Lesson");
            assertThat(response.getSummary().getMostMistakenQuestionText()).isEqualTo("Arabic Q");
            assertThat(response.getMistakes()).hasSize(2);
            assertThat(response.getMistakes())
                    .allMatch(row -> row.getSubjectId().equals(100L));
            assertThat(response.getMistakes())
                    .allMatch(row -> row.isCommonMistake());
            assertThat(response.getMistakes())
                    .extracting("subjectName")
                    .doesNotContain("Math");
        }

        @Test
        @DisplayName("teacher cannot see unrelated subject mistakes")
        void teacherCannotSeeUnrelatedSubjectMistakes() {
            Subject arabic = createSubject(100L, "Arabic", 1);

            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(1L, arabic)));

            TeacherMistakeAnalyticsResponse response = teacherService
                    .getMistakeAnalytics(10L, 300L, null, null, null);

            assertThat(response.getSummary().getTotalMistakes()).isZero();
            assertThat(response.getMistakes()).isEmpty();
            verifyNoInteractions(studentRepository, studentResponseRepository);
        }

        @Test
        @DisplayName("teacher with no assignments gets empty analytics")
        void teacherWithNoAssignmentsGetsEmptyAnalytics() {
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of());

            TeacherMistakeAnalyticsResponse response = teacherService
                    .getMistakeAnalytics(10L, null, null, null, null);

            assertThat(response.getSummary().getTotalMistakes()).isZero();
            assertThat(response.getSummary().getAffectedStudents()).isZero();
            assertThat(response.getMistakes()).isEmpty();
            verifyNoInteractions(studentRepository, studentResponseRepository);
        }

        @Test
        @DisplayName("filters by subject, lesson, student, and limit")
        void filtersBySubjectLessonStudentAndLimit() {
            Subject arabic = createSubject(100L, "Arabic", 1);
            Lesson lesson1 = createLesson(200L, arabic, "Lesson 1", 1);
            Lesson lesson2 = createLesson(201L, arabic, "Lesson 2", 2);
            Question lesson1Question = createQuestion(500L, lesson1, "Q1", 1);
            Question lesson2Question = createQuestion(501L, lesson2, "Q2", 1);
            StudentResponse matching = createMistakeResponse(
                    1L, student1, lesson1Question, "B", LocalDateTime.now().minusHours(1));
            StudentResponse otherStudent = createMistakeResponse(
                    2L, student2, lesson1Question, "C", LocalDateTime.now().minusHours(2));
            StudentResponse otherLesson = createMistakeResponse(
                    3L, student1, lesson2Question, "D", LocalDateTime.now());

            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(1L, arabic)));
            when(studentRepository.findBySchoolIdInAndGradeLevelIn(List.of(7L), List.of(1)))
                    .thenReturn(List.of(student1, student2));
            when(studentResponseRepository.findIncorrectByStudentIdsAndSubjectIds(
                    List.of(1L), List.of(100L), 100L, 200L, 1L))
                    .thenReturn(List.of(matching, otherStudent, otherLesson));

            TeacherMistakeAnalyticsResponse response = teacherService
                    .getMistakeAnalytics(10L, 100L, 200L, 1L, 1);

            assertThat(response.getSummary().getTotalMistakes()).isEqualTo(1);
            assertThat(response.getMistakes()).hasSize(1);
            assertThat(response.getMistakes().get(0).getStudentId()).isEqualTo(1L);
            assertThat(response.getMistakes().get(0).getLessonId()).isEqualTo(200L);
            assertThat(response.getMistakes().get(0).getQuestionText()).isEqualTo("Q1");
        }
    }

    // ==================== Question Bank Tests (FR-9) ====================

    @Nested
    @DisplayName("getAssignedSubjects()")
    class GetAssignedSubjectsTests {

        @Test
        @DisplayName("teacher assigned to Arabic sees only Arabic")
        void teacherAssignedToArabicSeesOnlyArabic() {
            Subject arabic = createSubject(100L, "Arabic", 1);
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(1L, arabic)));

            List<SubjectSummary> subjects = teacherService.getAssignedSubjects(10L);

            assertThat(subjects).extracting(SubjectSummary::getName)
                    .containsExactly("Arabic");
            assertThat(subjects).allMatch(s -> s.getGradeLevel() == 1);
            verifyNoInteractions(subjectRepository);
        }

        @Test
        @DisplayName("teacher assigned to Islamic sees only Islamic")
        void teacherAssignedToIslamicSeesOnlyIslamic() {
            Subject islamic = createSubject(101L, "Islamic", 1);
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(2L, islamic)));

            List<SubjectSummary> subjects = teacherService.getAssignedSubjects(10L);

            assertThat(subjects).extracting(SubjectSummary::getName)
                    .containsExactly("Islamic");
            assertThat(subjects).allMatch(s -> s.getGradeLevel() == 1);
            verifyNoInteractions(subjectRepository);
        }

        @Test
        @DisplayName("teacher with no assignments gets empty subject list")
        void teacherWithNoAssignmentsGetsEmptySubjectList() {
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of());

            List<SubjectSummary> subjects = teacherService.getAssignedSubjects(10L);

            assertThat(subjects).isEmpty();
            verifyNoInteractions(subjectRepository);
        }
    }

    @Nested
    @DisplayName("getQuestionsForSubject()")
    class GetQuestionsForSubjectTests {

        @Test
        @DisplayName("should return all questions when no filters applied")
        void returnsAllQuestions() {
            Subject arabic = createSubject(100L, "Arabic", 1);
            Lesson lesson1 = createLesson(200L, arabic, "Lesson 1", 1);
            Lesson lesson2 = createLesson(201L, arabic, "Lesson 2", 2);
            List<Question> questions = List.of(
                    createQuestion(1L, lesson1, "Q1", 1),
                    createQuestion(2L, lesson1, "Q2", 2),
                    createQuestion(3L, lesson2, "Q3", 1));

            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(subjectRepository.findById(100L)).thenReturn(Optional.of(arabic));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(1L, arabic)));
            when(questionRepository.findAllBySubjectIdWithLesson(100L)).thenReturn(questions);

            QuestionBankResponse response = teacherService.getQuestionsForSubject(
                    10L, 100L, null, null);

            assertThat(response.getQuestions()).hasSize(3);
            assertThat(response.getLessons()).hasSize(2);
            assertThat(response.getTotalQuestionsInSubject()).isEqualTo(3);
        }

        @Test
        @DisplayName("should filter by difficulty")
        void filtersByDifficulty() {
            Subject arabic = createSubject(100L, "Arabic", 1);
            Lesson lesson1 = createLesson(200L, arabic, "Lesson 1", 1);
            List<Question> questions = List.of(
                    createQuestion(1L, lesson1, "Q1", 1),
                    createQuestion(2L, lesson1, "Q2", 2),
                    createQuestion(3L, lesson1, "Q3", 1));

            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(subjectRepository.findById(100L)).thenReturn(Optional.of(arabic));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(1L, arabic)));
            when(questionRepository.findAllBySubjectIdWithLesson(100L)).thenReturn(questions);

            QuestionBankResponse response = teacherService.getQuestionsForSubject(
                    10L, 100L, 1, null);

            assertThat(response.getQuestions()).hasSize(2);
            assertThat(response.getQuestions())
                    .allMatch(q -> q.getDifficultyLevel() == 1);
            // Lessons filter dropdown still shows all lessons available in the subject
            assertThat(response.getLessons()).hasSize(1);
        }

        @Test
        @DisplayName("should filter by lesson")
        void filtersByLesson() {
            Subject arabic = createSubject(100L, "Arabic", 1);
            Lesson lesson1 = createLesson(200L, arabic, "Lesson 1", 1);
            Lesson lesson2 = createLesson(201L, arabic, "Lesson 2", 2);
            List<Question> questions = List.of(
                    createQuestion(1L, lesson1, "Q1", 1),
                    createQuestion(2L, lesson2, "Q2", 1));

            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(subjectRepository.findById(100L)).thenReturn(Optional.of(arabic));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(1L, arabic)));
            when(questionRepository.findAllBySubjectIdWithLesson(100L)).thenReturn(questions);

            QuestionBankResponse response = teacherService.getQuestionsForSubject(
                    10L, 100L, null, 201L);

            assertThat(response.getQuestions()).hasSize(1);
            assertThat(response.getQuestions().get(0).getLessonId()).isEqualTo(201L);
            assertThat(response.getLessons()).hasSize(2); // filter dropdown unchanged
        }

        @Test
        @DisplayName("teacher cannot access questions for unassigned subject")
        void deniesWhenSubjectUnassigned() {
            Subject math = createSubject(300L, "Math", 1);
            Subject arabic = createSubject(100L, "Arabic", 1);
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(subjectRepository.findById(300L)).thenReturn(Optional.of(math));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                    .thenReturn(List.of(createAssignment(1L, arabic)));

            assertThatThrownBy(() -> teacherService.getQuestionsForSubject(
                    10L, 300L, null, null))
                    .isInstanceOf(UnauthorizedException.class);
            verify(questionRepository, never()).findAllBySubjectIdWithLesson(anyLong());
            verify(teacherAssignmentRepository, never())
                    .existsActiveByTeacherIdAndSubjectId(anyLong(), anyLong());
        }

        @Test
        @DisplayName("teacher with no assignments cannot access subject questions")
        void teacherWithNoAssignmentsCannotAccessSubjectQuestions() {
            Teacher unassigned = new Teacher();
            unassigned.setId(20L);
            Subject any = createSubject(400L, "Any", 3);
            when(teacherRepository.findById(20L)).thenReturn(Optional.of(unassigned));
            when(subjectRepository.findById(400L)).thenReturn(Optional.of(any));
            when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(20L))
                    .thenReturn(List.of());

            assertThatThrownBy(() -> teacherService.getQuestionsForSubject(
                    20L, 400L, null, null))
                    .isInstanceOf(UnauthorizedException.class);
            verify(questionRepository, never()).findAllBySubjectIdWithLesson(anyLong());
            verify(teacherAssignmentRepository, never())
                    .existsActiveByTeacherIdAndSubjectId(anyLong(), anyLong());
        }
    }

    private Subject createSubject(Long id, String name, int grade) {
        Subject s = new Subject();
        s.setId(id);
        s.setName(name);
        s.setGradeLevel(grade);
        s.setLessons(new ArrayList<>());
        return s;
    }

    private TeacherAssignment createAssignment(Long id, Subject subject) {
        TeacherAssignment assignment = new TeacherAssignment();
        assignment.setId(id);
        assignment.setTeacher(teacher);
        assignment.setSubject(subject);
        assignment.setGradeLevel(subject.getGradeLevel());
        assignment.setSchool(school);
        assignment.setIsActive(true);
        return assignment;
    }

    private Lesson createLesson(Long id, Subject subject, String title, int order) {
        Lesson l = new Lesson();
        l.setId(id);
        l.setSubject(subject);
        l.setTitle(title);
        l.setOrderIndex(order);
        l.setQuestions(new ArrayList<>());
        return l;
    }

    private Question createQuestion(Long id, Lesson lesson, String text, int difficulty) {
        Question q = new Question();
        q.setId(id);
        q.setLesson(lesson);
        q.setType(QuestionType.MCQ);
        q.setQuestionText(text);
        q.setCorrectAnswer("A");
        q.setOptions("[\"A\",\"B\",\"C\"]");
        q.setDifficultyLevel(difficulty);
        return q;
    }

    // ==================== Helpers ====================

    private Progress createProgress(CompletionStatus status, double mastery) {
        Progress p = new Progress();
        p.setCompletionStatus(status);
        p.setMasteryLevel(mastery);
        return p;
    }

    /** Same as {@link #createProgress} but with Student and Lesson set for scoped metrics. */
    private Progress createProgressFor(
            Student student,
            Lesson lesson,
            CompletionStatus status,
            double mastery) {
        Progress p = createProgress(status, mastery);
        p.setStudent(student);
        p.setLesson(lesson);
        return p;
    }

    private Attempt createAttempt(AttemptStatus status, double score) {
        Attempt a = new Attempt();
        a.setStatus(status);
        a.setScore(score);
        return a;
    }

    private StudentResponse createMistakeResponse(
            Long id,
            Student student,
            Question question,
            String answer,
            LocalDateTime submittedAt) {
        Attempt attempt = new Attempt();
        attempt.setId(1000L + id);
        attempt.setStudent(student);
        attempt.setStatus(AttemptStatus.GRADED);
        attempt.setCreatedAt(submittedAt.minusMinutes(5));
        attempt.setSubmittedAt(submittedAt);

        StudentResponse response = new StudentResponse();
        response.setId(id);
        response.setAttempt(attempt);
        response.setQuestion(question);
        response.setIsCorrect(false);
        response.setEvaluatedText(answer);
        response.setFeedback("wrong");
        return response;
    }
}
