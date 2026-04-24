package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.ClassStudentSummary;
import com.springboot.manhaji.dto.response.QuestionBankResponse;
import com.springboot.manhaji.dto.response.StudentDetailResponse;
import com.springboot.manhaji.dto.response.SubjectSummary;
import com.springboot.manhaji.dto.response.TeacherDashboardResponse;
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
import com.springboot.manhaji.support.TestMessages;
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
    @Mock private StudentRepository studentRepository;
    @Mock private ProgressRepository progressRepository;
    @Mock private AttemptRepository attemptRepository;
    @Mock private SubjectRepository subjectRepository;
    @Mock private LessonRepository lessonRepository;
    @Mock private QuestionRepository questionRepository;

    private TeacherService teacherService;

    private Teacher teacher;
    private Student student1;
    private Student student2;

    @BeforeEach
    void setUp() {
        ProgressMetrics metrics = new ProgressMetrics(subjectRepository, lessonRepository);
        QuestionBankMapper questionBankMapper = new QuestionBankMapper();
        teacherService = new TeacherService(
                teacherRepository, studentRepository, progressRepository, attemptRepository,
                subjectRepository, questionRepository, questionBankMapper,
                metrics, TestMessages.create());

        teacher = new Teacher();
        teacher.setId(10L);
        teacher.setFullName("أستاذ أحمد");
        teacher.setDepartment("اللغة العربية");
        teacher.setAssignedGrade(1);
        teacher.setRole(Role.TEACHER);

        student1 = new Student();
        student1.setId(1L);
        student1.setFullName("طالب واحد");
        student1.setEmail("s1@test.com");
        student1.setGradeLevel(1);
        student1.setTotalPoints(100);
        student1.setCurrentStreak(3);
        student1.setLastLoginAt(LocalDateTime.now().minusDays(1));

        student2 = new Student();
        student2.setId(2L);
        student2.setFullName("طالب اثنان");
        student2.setEmail("s2@test.com");
        student2.setGradeLevel(1);
        student2.setTotalPoints(50);
        student2.setCurrentStreak(1);
        student2.setLastLoginAt(LocalDateTime.now().minusDays(10));
    }

    // ==================== getDashboard Tests ====================

    @Nested
    @DisplayName("getDashboard()")
    class GetDashboardTests {

        @Test
        @DisplayName("should return dashboard with student stats")
        void getDashboardSuccess() {
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(studentRepository.findByGradeLevel(1)).thenReturn(List.of(student1, student2));
            when(progressRepository.findByStudentId(1L)).thenReturn(List.of(
                    createProgress(CompletionStatus.COMPLETED, 85.0),
                    createProgress(CompletionStatus.IN_PROGRESS, 40.0)
            ));
            when(progressRepository.findByStudentId(2L)).thenReturn(List.of(
                    createProgress(CompletionStatus.COMPLETED, 70.0)
            ));

            TeacherDashboardResponse response = teacherService.getDashboard(10L);

            assertThat(response.getTeacherId()).isEqualTo(10L);
            assertThat(response.getFullName()).isEqualTo("أستاذ أحمد");
            assertThat(response.getTotalStudents()).isEqualTo(2);
            assertThat(response.getActiveThisWeek()).isEqualTo(1); // Only student1 logged in within 7 days
            assertThat(response.getLessonsCompletedTotal()).isEqualTo(2); // 1 completed per student
            assertThat(response.getTopStudents()).hasSizeLessThanOrEqualTo(5);
        }

        @Test
        @DisplayName("should throw when teacher not found")
        void teacherNotFound() {
            when(teacherRepository.findById(999L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> teacherService.getDashboard(999L))
                    .isInstanceOf(ResourceNotFoundException.class);
        }

        @Test
        @DisplayName("should fallback to all students when no grade/school")
        void fallbackToAllStudents() {
            Teacher unassigned = new Teacher();
            unassigned.setId(20L);
            unassigned.setFullName("أستاذ بدون تعيين");
            // No school, no grade

            when(teacherRepository.findById(20L)).thenReturn(Optional.of(unassigned));
            when(studentRepository.findAll()).thenReturn(List.of(student1, student2));
            when(progressRepository.findByStudentId(anyLong())).thenReturn(List.of());

            TeacherDashboardResponse response = teacherService.getDashboard(20L);

            assertThat(response.getTotalStudents()).isEqualTo(2);
            verify(studentRepository).findAll(); // fallback path
        }
    }

    // ==================== getStudents Tests ====================

    @Nested
    @DisplayName("getStudents()")
    class GetStudentsTests {

        @Test
        @DisplayName("should return sorted student list")
        void getStudentsSorted() {
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(studentRepository.findByGradeLevel(1)).thenReturn(List.of(student1, student2));
            when(progressRepository.findByStudentId(anyLong())).thenReturn(List.of());

            List<ClassStudentSummary> students = teacherService.getStudents(10L);

            assertThat(students).hasSize(2);
            // Sorted by name alphabetically
            assertThat(students.get(0).getFullName()).isEqualTo("طالب اثنان");
            assertThat(students.get(1).getFullName()).isEqualTo("طالب واحد");
        }
    }

    // ==================== getStudentDetail Tests ====================

    @Nested
    @DisplayName("getStudentDetail()")
    class GetStudentDetailTests {

        @Test
        @DisplayName("should return detailed student info")
        void getStudentDetailSuccess() {
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(studentRepository.findById(1L)).thenReturn(Optional.of(student1));
            when(progressRepository.findByStudentId(1L)).thenReturn(List.of(
                    createProgress(CompletionStatus.COMPLETED, 90.0)
            ));
            when(attemptRepository.findByStudentIdOrderByCreatedAtDesc(1L)).thenReturn(List.of(
                    createAttempt(AttemptStatus.GRADED, 85.0)
            ));
            when(subjectRepository.findByGradeLevel(1)).thenReturn(List.of());

            StudentDetailResponse detail = teacherService.getStudentDetail(10L, 1L);

            assertThat(detail.getStudentId()).isEqualTo(1L);
            assertThat(detail.getFullName()).isEqualTo("طالب واحد");
            assertThat(detail.getLessonsCompleted()).isEqualTo(1);
            assertThat(detail.getTotalAttempts()).isEqualTo(1);
            assertThat(detail.getAverageScore()).isEqualTo(85.0);
        }

        @Test
        @DisplayName("should deny access when student grade doesn't match teacher")
        void denyAccessWrongGrade() {
            Student grade2Student = new Student();
            grade2Student.setId(3L);
            grade2Student.setGradeLevel(2); // Teacher is assigned grade 1

            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(studentRepository.findById(3L)).thenReturn(Optional.of(grade2Student));

            assertThatThrownBy(() -> teacherService.getStudentDetail(10L, 3L))
                    .isInstanceOf(UnauthorizedException.class);
        }
    }

    // ==================== Question Bank Tests (FR-9) ====================

    @Nested
    @DisplayName("getAssignedSubjects()")
    class GetAssignedSubjectsTests {

        @Test
        @DisplayName("should return subjects at teacher's assigned grade")
        void returnsSubjectsAtAssignedGrade() {
            Subject arabic = createSubject(100L, "Arabic", 1);
            Subject math = createSubject(101L, "Math", 1);
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(subjectRepository.findByGradeLevel(1)).thenReturn(List.of(arabic, math));

            List<SubjectSummary> subjects = teacherService.getAssignedSubjects(10L);

            assertThat(subjects).hasSize(2);
            assertThat(subjects).extracting(SubjectSummary::getName)
                    .containsExactly("Arabic", "Math");
            assertThat(subjects).allMatch(s -> s.getGradeLevel() == 1);
        }

        @Test
        @DisplayName("should fall back to all subjects when teacher has no grade")
        void fallbackAllSubjectsWhenNoGrade() {
            Teacher unassigned = new Teacher();
            unassigned.setId(20L);
            when(teacherRepository.findById(20L)).thenReturn(Optional.of(unassigned));
            when(subjectRepository.findAll()).thenReturn(
                    List.of(createSubject(1L, "Any", 1)));

            List<SubjectSummary> subjects = teacherService.getAssignedSubjects(20L);

            assertThat(subjects).hasSize(1);
            verify(subjectRepository).findAll();
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
            when(questionRepository.findAllBySubjectIdWithLesson(100L)).thenReturn(questions);

            QuestionBankResponse response = teacherService.getQuestionsForSubject(
                    10L, 100L, null, 201L);

            assertThat(response.getQuestions()).hasSize(1);
            assertThat(response.getQuestions().get(0).getLessonId()).isEqualTo(201L);
            assertThat(response.getLessons()).hasSize(2); // filter dropdown unchanged
        }

        @Test
        @DisplayName("should deny access when subject is at a different grade")
        void deniesWhenSubjectWrongGrade() {
            Subject grade2Subject = createSubject(300L, "Grade2Arabic", 2);
            when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
            when(subjectRepository.findById(300L)).thenReturn(Optional.of(grade2Subject));

            assertThatThrownBy(() -> teacherService.getQuestionsForSubject(
                    10L, 300L, null, null))
                    .isInstanceOf(UnauthorizedException.class);
        }

        @Test
        @DisplayName("should allow unassigned teacher (no grade) to see any subject")
        void unassignedTeacherBypassesGuard() {
            Teacher unassigned = new Teacher();
            unassigned.setId(20L);
            Subject any = createSubject(400L, "Any", 3);
            when(teacherRepository.findById(20L)).thenReturn(Optional.of(unassigned));
            when(subjectRepository.findById(400L)).thenReturn(Optional.of(any));
            when(questionRepository.findAllBySubjectIdWithLesson(400L))
                    .thenReturn(new ArrayList<>());

            QuestionBankResponse response = teacherService.getQuestionsForSubject(
                    20L, 400L, null, null);

            assertThat(response.getSubjectId()).isEqualTo(400L);
            assertThat(response.getQuestions()).isEmpty();
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

    private Attempt createAttempt(AttemptStatus status, double score) {
        Attempt a = new Attempt();
        a.setStatus(status);
        a.setScore(score);
        return a;
    }
}
