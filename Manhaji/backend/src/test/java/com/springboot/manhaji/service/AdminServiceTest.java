package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.AdminStatsResponse;
import com.springboot.manhaji.dto.response.QuestionBankResponse;
import com.springboot.manhaji.dto.response.SubjectSummary;
import com.springboot.manhaji.dto.response.UserSummaryResponse;
import com.springboot.manhaji.entity.Admin;
import com.springboot.manhaji.entity.Attempt;
import com.springboot.manhaji.entity.Lesson;
import com.springboot.manhaji.entity.Progress;
import com.springboot.manhaji.entity.Question;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.Teacher;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.repository.*;
import com.springboot.manhaji.service.support.QuestionBankMapper;
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
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminServiceTest {

    @Mock private UserRepository userRepository;
    @Mock private StudentRepository studentRepository;
    @Mock private TeacherRepository teacherRepository;
    @Mock private ParentRepository parentRepository;
    @Mock private AdminRepository adminRepository;
    @Mock private SubjectRepository subjectRepository;
    @Mock private LessonRepository lessonRepository;
    @Mock private QuestionRepository questionRepository;
    @Mock private AttemptRepository attemptRepository;
    @Mock private ProgressRepository progressRepository;

    private AdminService adminService;

    @BeforeEach
    void setUp() {
        adminService = new AdminService(
                userRepository, studentRepository, teacherRepository, parentRepository,
                adminRepository, subjectRepository, lessonRepository, questionRepository,
                attemptRepository, progressRepository, new QuestionBankMapper());
    }

    // ==================== getStats Tests ====================

    @Nested
    @DisplayName("getStats()")
    class GetStatsTests {

        @Test
        @DisplayName("should return correct platform statistics")
        void getStatsSuccess() {
            when(studentRepository.count()).thenReturn(10L);
            when(teacherRepository.count()).thenReturn(3L);
            when(parentRepository.count()).thenReturn(5L);
            when(adminRepository.count()).thenReturn(1L);
            when(subjectRepository.count()).thenReturn(4L);
            when(lessonRepository.count()).thenReturn(20L);

            Student activeStudent = new Student();
            activeStudent.setLastLoginAt(LocalDateTime.now().minusDays(2));
            Student inactiveStudent = new Student();
            inactiveStudent.setLastLoginAt(LocalDateTime.now().minusDays(30));
            when(studentRepository.findAll()).thenReturn(List.of(activeStudent, inactiveStudent));

            Attempt gradedAttempt = new Attempt();
            gradedAttempt.setStatus(AttemptStatus.GRADED);
            Attempt inProgressAttempt = new Attempt();
            inProgressAttempt.setStatus(AttemptStatus.IN_PROGRESS);
            when(attemptRepository.findAll()).thenReturn(List.of(gradedAttempt, inProgressAttempt));

            Progress completedProgress = new Progress();
            completedProgress.setCompletionStatus(CompletionStatus.COMPLETED);
            Progress inProgressProgress = new Progress();
            inProgressProgress.setCompletionStatus(CompletionStatus.IN_PROGRESS);
            when(progressRepository.findAll()).thenReturn(List.of(completedProgress, inProgressProgress));

            AdminStatsResponse stats = adminService.getStats();

            assertThat(stats.getTotalStudents()).isEqualTo(10);
            assertThat(stats.getTotalTeachers()).isEqualTo(3);
            assertThat(stats.getTotalParents()).isEqualTo(5);
            assertThat(stats.getTotalAdmins()).isEqualTo(1);
            assertThat(stats.getTotalSubjects()).isEqualTo(4);
            assertThat(stats.getTotalLessons()).isEqualTo(20);
            assertThat(stats.getActiveStudentsThisWeek()).isEqualTo(1);
            assertThat(stats.getTotalAttempts()).isEqualTo(1); // only GRADED
            assertThat(stats.getTotalCompletedLessons()).isEqualTo(1);
        }

        @Test
        @DisplayName("should handle zero data correctly")
        void getStatsEmpty() {
            when(studentRepository.count()).thenReturn(0L);
            when(teacherRepository.count()).thenReturn(0L);
            when(parentRepository.count()).thenReturn(0L);
            when(adminRepository.count()).thenReturn(0L);
            when(subjectRepository.count()).thenReturn(0L);
            when(lessonRepository.count()).thenReturn(0L);
            when(studentRepository.findAll()).thenReturn(List.of());
            when(attemptRepository.findAll()).thenReturn(List.of());
            when(progressRepository.findAll()).thenReturn(List.of());

            AdminStatsResponse stats = adminService.getStats();

            assertThat(stats.getTotalStudents()).isZero();
            assertThat(stats.getActiveStudentsThisWeek()).isZero();
            assertThat(stats.getTotalAttempts()).isZero();
            assertThat(stats.getTotalCompletedLessons()).isZero();
        }
    }

    // ==================== getAllUsers Tests ====================

    @Nested
    @DisplayName("getAllUsers()")
    class GetAllUsersTests {

        @Test
        @DisplayName("should return all users when no role filter")
        void getAllUsersNoFilter() {
            Student student = new Student();
            student.setId(1L);
            student.setFullName("طالب");
            student.setRole(Role.STUDENT);
            student.setIsActive(true);
            student.setGradeLevel(1);

            Teacher teacher = new Teacher();
            teacher.setId(2L);
            teacher.setFullName("معلم");
            teacher.setRole(Role.TEACHER);
            teacher.setIsActive(true);

            when(userRepository.findAll()).thenReturn(List.of(student, teacher));

            List<UserSummaryResponse> users = adminService.getAllUsers(null);

            assertThat(users).hasSize(2);
        }

        @Test
        @DisplayName("should filter by role")
        void filterByRole() {
            Student student = new Student();
            student.setId(1L);
            student.setFullName("طالب");
            student.setRole(Role.STUDENT);
            student.setIsActive(true);
            student.setGradeLevel(1);

            Teacher teacher = new Teacher();
            teacher.setId(2L);
            teacher.setFullName("معلم");
            teacher.setRole(Role.TEACHER);
            teacher.setIsActive(true);

            when(userRepository.findAll()).thenReturn(List.of(student, teacher));

            List<UserSummaryResponse> students = adminService.getAllUsers(Role.STUDENT);

            assertThat(students).hasSize(1);
            assertThat(students.get(0).getRole()).isEqualTo(Role.STUDENT);
            assertThat(students.get(0).getGradeLevel()).isEqualTo(1);
        }

        @Test
        @DisplayName("should include gradeLevel only for students")
        void gradeLevelOnlyForStudents() {
            Student student = new Student();
            student.setId(1L);
            student.setFullName("طالب");
            student.setRole(Role.STUDENT);
            student.setIsActive(true);
            student.setGradeLevel(1);

            Admin admin = new Admin();
            admin.setId(2L);
            admin.setFullName("مسؤول");
            admin.setRole(Role.ADMIN);
            admin.setIsActive(true);

            when(userRepository.findAll()).thenReturn(List.of(student, admin));

            List<UserSummaryResponse> users = adminService.getAllUsers(null);

            var studentSummary = users.stream()
                    .filter(u -> u.getRole() == Role.STUDENT)
                    .findFirst().orElseThrow();
            var adminSummary = users.stream()
                    .filter(u -> u.getRole() == Role.ADMIN)
                    .findFirst().orElseThrow();

            assertThat(studentSummary.getGradeLevel()).isEqualTo(1);
            assertThat(adminSummary.getGradeLevel()).isNull();
        }
    }

    // ==================== getAllSubjects Tests ====================

    @Nested
    @DisplayName("getAllSubjects()")
    class GetAllSubjectsTests {

        @Test
        @DisplayName("should return all subjects unrestricted when no grade filter")
        void returnsAllSubjectsUnrestricted() {
            Subject arabic = createSubject(1L, "اللغة العربية", 1);
            Subject english = createSubject(2L, "English", 2);
            Subject math = createSubject(3L, "الرياضيات", 1);

            when(subjectRepository.findAll()).thenReturn(List.of(arabic, english, math));

            List<SubjectSummary> result = adminService.getAllSubjects(null);

            assertThat(result).hasSize(3);
            // Sorted by gradeLevel asc, then name asc within grade
            assertThat(result.get(0).getGradeLevel()).isEqualTo(1);
            assertThat(result.get(1).getGradeLevel()).isEqualTo(1);
            assertThat(result.get(2).getGradeLevel()).isEqualTo(2);
            verify(subjectRepository).findAll();
            verify(subjectRepository, never()).findByGradeLevel(anyInt());
        }

        @Test
        @DisplayName("should filter by grade when gradeFilter provided")
        void filtersByGrade() {
            Subject arabicG1 = createSubject(1L, "اللغة العربية", 1);
            Subject mathG1 = createSubject(2L, "الرياضيات", 1);

            when(subjectRepository.findByGradeLevel(1)).thenReturn(List.of(arabicG1, mathG1));

            List<SubjectSummary> result = adminService.getAllSubjects(1);

            assertThat(result).hasSize(2);
            assertThat(result).allMatch(s -> s.getGradeLevel() == 1);
            verify(subjectRepository).findByGradeLevel(1);
            verify(subjectRepository, never()).findAll();
        }
    }

    // ==================== getQuestionsForSubject Tests ====================

    @Nested
    @DisplayName("getQuestionsForSubject()")
    class GetQuestionsForSubjectTests {

        @Test
        @DisplayName("should return all questions for subject without grade guard")
        void returnsAllQuestionsUnrestricted() {
            Subject subject = createSubject(10L, "اللغة العربية", 1);
            Lesson lesson = createLesson(100L, "حرف الراء", 1, subject);
            Question q1 = createQuestion(1L, QuestionType.MCQ, 1, lesson);
            Question q2 = createQuestion(2L, QuestionType.PRONUNCIATION, 2, lesson);

            when(subjectRepository.findById(10L)).thenReturn(Optional.of(subject));
            when(questionRepository.findAllBySubjectIdWithLesson(10L))
                    .thenReturn(List.of(q1, q2));

            QuestionBankResponse response = adminService.getQuestionsForSubject(10L, null, null);

            assertThat(response.getSubjectId()).isEqualTo(10L);
            assertThat(response.getGradeLevel()).isEqualTo(1);
            assertThat(response.getQuestions()).hasSize(2);
            assertThat(response.getTotalQuestionsInSubject()).isEqualTo(2);
        }

        @Test
        @DisplayName("should filter questions by difficulty")
        void filtersByDifficulty() {
            Subject subject = createSubject(10L, "اللغة العربية", 1);
            Lesson lesson = createLesson(100L, "حرف الراء", 1, subject);
            Question easy = createQuestion(1L, QuestionType.MCQ, 1, lesson);
            Question medium = createQuestion(2L, QuestionType.MCQ, 2, lesson);
            Question hard = createQuestion(3L, QuestionType.MCQ, 3, lesson);

            when(subjectRepository.findById(10L)).thenReturn(Optional.of(subject));
            when(questionRepository.findAllBySubjectIdWithLesson(10L))
                    .thenReturn(List.of(easy, medium, hard));

            QuestionBankResponse response = adminService.getQuestionsForSubject(10L, 2, null);

            assertThat(response.getQuestions()).hasSize(1);
            assertThat(response.getQuestions().get(0).getDifficultyLevel()).isEqualTo(2);
            // Total unfiltered count preserved
            assertThat(response.getTotalQuestionsInSubject()).isEqualTo(3);
        }

        @Test
        @DisplayName("should filter questions by lesson")
        void filtersByLesson() {
            Subject subject = createSubject(10L, "اللغة العربية", 1);
            Lesson lessonA = createLesson(100L, "حرف الراء", 1, subject);
            Lesson lessonB = createLesson(101L, "حرف السين", 2, subject);
            Question q1 = createQuestion(1L, QuestionType.MCQ, 1, lessonA);
            Question q2 = createQuestion(2L, QuestionType.MCQ, 1, lessonB);

            when(subjectRepository.findById(10L)).thenReturn(Optional.of(subject));
            when(questionRepository.findAllBySubjectIdWithLesson(10L))
                    .thenReturn(List.of(q1, q2));

            QuestionBankResponse response = adminService.getQuestionsForSubject(10L, null, 100L);

            assertThat(response.getQuestions()).hasSize(1);
            assertThat(response.getQuestions().get(0).getLessonId()).isEqualTo(100L);
            assertThat(response.getLessons()).hasSize(2); // lessons list is unfiltered
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when subject missing")
        void throwsWhenSubjectMissing() {
            when(subjectRepository.findById(999L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> adminService.getQuestionsForSubject(999L, null, null))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(questionRepository, never()).findAllBySubjectIdWithLesson(anyLong());
        }
    }

    // ==================== Helpers ====================

    private Subject createSubject(Long id, String name, Integer gradeLevel) {
        Subject s = new Subject();
        s.setId(id);
        s.setName(name);
        s.setGradeLevel(gradeLevel);
        s.setLessons(new ArrayList<>());
        return s;
    }

    private Lesson createLesson(Long id, String title, Integer orderIndex, Subject subject) {
        Lesson l = new Lesson();
        l.setId(id);
        l.setTitle(title);
        l.setOrderIndex(orderIndex);
        l.setSubject(subject);
        if (subject.getLessons() != null) {
            subject.getLessons().add(l);
        }
        return l;
    }

    private Question createQuestion(Long id, QuestionType type, Integer difficulty, Lesson lesson) {
        Question q = new Question();
        q.setId(id);
        q.setType(type);
        q.setQuestionText("نص السؤال " + id);
        q.setCorrectAnswer("answer");
        q.setDifficultyLevel(difficulty);
        q.setLesson(lesson);
        return q;
    }
}
