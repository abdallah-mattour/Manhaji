package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.request.AdminCreateUserRequest;
import com.springboot.manhaji.dto.request.AdminUpdateUserRequest;
import com.springboot.manhaji.dto.response.AdminStatsResponse;
import com.springboot.manhaji.dto.response.QuestionBankResponse;
import com.springboot.manhaji.dto.response.SubjectSummary;
import com.springboot.manhaji.dto.response.UserSummaryResponse;
import com.springboot.manhaji.entity.Admin;
import com.springboot.manhaji.entity.Attempt;
import com.springboot.manhaji.entity.Lesson;
import com.springboot.manhaji.entity.Parent;
import com.springboot.manhaji.entity.Progress;
import com.springboot.manhaji.entity.Question;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.Teacher;
import com.springboot.manhaji.entity.User;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.exception.BadRequestException;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.infrastructure.Messages;
import com.springboot.manhaji.repository.*;
import com.springboot.manhaji.service.support.QuestionBankMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
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
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private Messages messages;

    private AdminService adminService;

    @BeforeEach
    void setUp() {
        adminService = new AdminService(
                userRepository, studentRepository, teacherRepository, parentRepository,
                adminRepository, subjectRepository, lessonRepository, questionRepository,
                attemptRepository, progressRepository, new QuestionBankMapper(),
                passwordEncoder, messages);
        lenient().when(messages.get(anyString(), any(Object[].class)))
                .thenAnswer(inv -> inv.getArgument(0));
        lenient().when(messages.get(anyString())).thenAnswer(inv -> inv.getArgument(0));
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

    // ==================== createUser Tests ====================

    @Nested
    @DisplayName("createUser()")
    class CreateUserTests {

        @Test
        @DisplayName("should create a student with hashed password")
        void createStudent() {
            AdminCreateUserRequest req = new AdminCreateUserRequest();
            req.setFullName("سعد علي");
            req.setEmail("saad@example.com");
            req.setPassword("secret123");
            req.setRole(Role.STUDENT);
            req.setGradeLevel(2);

            when(userRepository.existsByEmail("saad@example.com")).thenReturn(false);
            when(passwordEncoder.encode("secret123")).thenReturn("HASH");
            when(userRepository.save(any(User.class))).thenAnswer(inv -> {
                User u = inv.getArgument(0);
                u.setId(42L);
                return u;
            });

            UserSummaryResponse result = adminService.createUser(req);

            assertThat(result.getUserId()).isEqualTo(42L);
            assertThat(result.getRole()).isEqualTo(Role.STUDENT);
            assertThat(result.getGradeLevel()).isEqualTo(2);
            assertThat(result.getFullName()).isEqualTo("سعد علي");

            verify(passwordEncoder).encode("secret123");
        }

        @Test
        @DisplayName("should create a teacher with department + assignedGrade")
        void createTeacher() {
            AdminCreateUserRequest req = new AdminCreateUserRequest();
            req.setFullName("Ms. Sara");
            req.setPhone("0599123456");
            req.setPassword("p4ssword");
            req.setRole(Role.TEACHER);
            req.setDepartment("Arabic");
            req.setAssignedGrade(1);

            when(userRepository.existsByPhone("0599123456")).thenReturn(false);
            when(passwordEncoder.encode("p4ssword")).thenReturn("HASH");
            when(userRepository.save(any(User.class))).thenAnswer(inv -> {
                User u = inv.getArgument(0);
                u.setId(7L);
                return u;
            });

            UserSummaryResponse result = adminService.createUser(req);

            assertThat(result.getRole()).isEqualTo(Role.TEACHER);
            assertThat(result.getPhone()).isEqualTo("0599123456");
            assertThat(result.getDepartment()).isEqualTo("Arabic");
            assertThat(result.getAssignedGrade()).isEqualTo(1);
        }

        @Test
        @DisplayName("should create a parent account with no role-specific fields")
        void createParent() {
            AdminCreateUserRequest req = new AdminCreateUserRequest();
            req.setFullName("Sarah Parent");
            req.setPhone("0599111222");
            req.setPassword("pass1234");
            req.setRole(Role.PARENT);

            when(userRepository.existsByPhone("0599111222")).thenReturn(false);
            when(passwordEncoder.encode("pass1234")).thenReturn("HASH");
            when(userRepository.save(any(User.class))).thenAnswer(inv -> {
                User u = inv.getArgument(0);
                u.setId(20L);
                return u;
            });

            UserSummaryResponse result = adminService.createUser(req);

            assertThat(result.getRole()).isEqualTo(Role.PARENT);
            assertThat(result.getGradeLevel()).isNull();
            assertThat(result.getDepartment()).isNull();
            assertThat(result.getAssignedGrade()).isNull();
            verify(passwordEncoder).encode("pass1234");
        }

        @Test
        @DisplayName("should reject non-manageable roles (ADMIN)")
        void rejectsNonManageableRole() {
            AdminCreateUserRequest req = new AdminCreateUserRequest();
            req.setFullName("X");
            req.setEmail("x@example.com");
            req.setPassword("secret123");
            req.setRole(Role.ADMIN);

            assertThatThrownBy(() -> adminService.createUser(req))
                    .isInstanceOf(BadRequestException.class);
            verify(userRepository, never()).save(any(User.class));
        }

        @Test
        @DisplayName("should reject student without gradeLevel")
        void rejectsStudentWithoutGrade() {
            AdminCreateUserRequest req = new AdminCreateUserRequest();
            req.setFullName("Y");
            req.setEmail("y@example.com");
            req.setPassword("secret123");
            req.setRole(Role.STUDENT);

            when(userRepository.existsByEmail("y@example.com")).thenReturn(false);

            assertThatThrownBy(() -> adminService.createUser(req))
                    .isInstanceOf(BadRequestException.class);
            verify(userRepository, never()).save(any(User.class));
        }

        @Test
        @DisplayName("should reject duplicate email")
        void rejectsDuplicateEmail() {
            AdminCreateUserRequest req = new AdminCreateUserRequest();
            req.setFullName("Z");
            req.setEmail("z@example.com");
            req.setPassword("secret123");
            req.setRole(Role.STUDENT);
            req.setGradeLevel(1);

            when(userRepository.existsByEmail("z@example.com")).thenReturn(true);

            assertThatThrownBy(() -> adminService.createUser(req))
                    .isInstanceOf(BadRequestException.class);
            verify(userRepository, never()).save(any(User.class));
        }
    }

    // ==================== updateUser Tests ====================

    @Nested
    @DisplayName("updateUser()")
    class UpdateUserTests {

        @Test
        @DisplayName("should patch only provided fields")
        void patchesProvidedFieldsOnly() {
            Student student = new Student();
            student.setId(5L);
            student.setRole(Role.STUDENT);
            student.setFullName("Old Name");
            student.setEmail("old@example.com");
            student.setGradeLevel(1);
            student.setPasswordHash("OLDHASH");
            student.setIsActive(true);

            when(userRepository.findById(5L)).thenReturn(Optional.of(student));
            when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

            AdminUpdateUserRequest req = new AdminUpdateUserRequest();
            req.setFullName("New Name");
            req.setGradeLevel(3);

            UserSummaryResponse result = adminService.updateUser(5L, req);

            assertThat(result.getFullName()).isEqualTo("New Name");
            assertThat(result.getGradeLevel()).isEqualTo(3);
            assertThat(result.getEmail()).isEqualTo("old@example.com");
            // password unchanged
            assertThat(student.getPasswordHash()).isEqualTo("OLDHASH");
        }

        @Test
        @DisplayName("should hash new password when provided")
        void rehashesPasswordWhenProvided() {
            Teacher teacher = new Teacher();
            teacher.setId(8L);
            teacher.setRole(Role.TEACHER);
            teacher.setPasswordHash("OLD");

            when(userRepository.findById(8L)).thenReturn(Optional.of(teacher));
            when(passwordEncoder.encode("newpass")).thenReturn("NEWHASH");
            when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

            AdminUpdateUserRequest req = new AdminUpdateUserRequest();
            req.setPassword("newpass");

            adminService.updateUser(8L, req);

            assertThat(teacher.getPasswordHash()).isEqualTo("NEWHASH");
        }

        @Test
        @DisplayName("should reject updates on ADMIN users")
        void rejectsAdminTarget() {
            Admin admin = new Admin();
            admin.setId(1L);
            admin.setRole(Role.ADMIN);
            when(userRepository.findById(1L)).thenReturn(Optional.of(admin));

            assertThatThrownBy(() -> adminService.updateUser(1L, new AdminUpdateUserRequest()))
                    .isInstanceOf(BadRequestException.class);
        }

        @Test
        @DisplayName("should deactivate a parent account")
        void deactivatesParent() {
            Parent parent = new Parent();
            parent.setId(15L);
            parent.setRole(Role.PARENT);
            parent.setIsActive(true);

            when(userRepository.findById(15L)).thenReturn(Optional.of(parent));
            when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

            AdminUpdateUserRequest req = new AdminUpdateUserRequest();
            req.setIsActive(false);

            UserSummaryResponse result = adminService.updateUser(15L, req);

            assertThat(result.getRole()).isEqualTo(Role.PARENT);
            assertThat(parent.getIsActive()).isFalse();
            assertThat(result.getGradeLevel()).isNull();
            assertThat(result.getDepartment()).isNull();
        }

        @Test
        @DisplayName("should return department and assignedGrade for teacher")
        void returnsDepartmentAndGradeForTeacher() {
            Teacher teacher = new Teacher();
            teacher.setId(9L);
            teacher.setRole(Role.TEACHER);
            teacher.setDepartment("Math");
            teacher.setAssignedGrade(2);

            when(userRepository.findById(9L)).thenReturn(Optional.of(teacher));
            when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

            UserSummaryResponse result = adminService.updateUser(9L, new AdminUpdateUserRequest());

            assertThat(result.getDepartment()).isEqualTo("Math");
            assertThat(result.getAssignedGrade()).isEqualTo(2);
            assertThat(result.getGradeLevel()).isNull();
        }

        @Test
        @DisplayName("should reject when target user not found")
        void rejectsMissingUser() {
            when(userRepository.findById(404L)).thenReturn(Optional.empty());
            assertThatThrownBy(() -> adminService.updateUser(404L, new AdminUpdateUserRequest()))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    // ==================== deleteUser Tests ====================

    @Nested
    @DisplayName("deleteUser()")
    class DeleteUserTests {

        @Test
        @DisplayName("should delete a parent account")
        void deletesParent() {
            Parent parent = new Parent();
            parent.setId(12L);
            parent.setRole(Role.PARENT);
            when(userRepository.findById(12L)).thenReturn(Optional.of(parent));

            adminService.deleteUser(12L, 99L);

            verify(userRepository).delete(parent);
        }

        @Test
        @DisplayName("should delete a student")
        void deletesStudent() {
            Student student = new Student();
            student.setId(7L);
            student.setRole(Role.STUDENT);
            when(userRepository.findById(7L)).thenReturn(Optional.of(student));

            adminService.deleteUser(7L, 2L);

            verify(userRepository).delete(student);
        }

        @Test
        @DisplayName("should reject self-deletion")
        void rejectsSelfDelete() {
            Student student = new Student();
            student.setId(2L);
            student.setRole(Role.STUDENT);
            when(userRepository.findById(2L)).thenReturn(Optional.of(student));

            assertThatThrownBy(() -> adminService.deleteUser(2L, 2L))
                    .isInstanceOf(BadRequestException.class);
            verify(userRepository, never()).delete(any(User.class));
        }

        @Test
        @DisplayName("should reject deletion of ADMIN")
        void rejectsAdminDelete() {
            Admin admin = new Admin();
            admin.setId(1L);
            admin.setRole(Role.ADMIN);
            when(userRepository.findById(1L)).thenReturn(Optional.of(admin));

            assertThatThrownBy(() -> adminService.deleteUser(1L, 99L))
                    .isInstanceOf(BadRequestException.class);
            verify(userRepository, never()).delete(any(User.class));
        }
    }

    // ==================== linkStudentToParent Tests ====================

    @Nested
    @DisplayName("linkStudentToParent()")
    class LinkStudentToParentTests {

        @Test
        @DisplayName("should link a student to a parent and return parentId in summary")
        void linksStudentToParent() {
            Student student = new Student();
            student.setId(1L);
            student.setRole(Role.STUDENT);
            student.setGradeLevel(1);

            Parent parent = new Parent();
            parent.setId(10L);
            parent.setRole(Role.PARENT);

            when(userRepository.findById(1L)).thenReturn(Optional.of(student));
            when(parentRepository.findById(10L)).thenReturn(Optional.of(parent));
            when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

            UserSummaryResponse result = adminService.linkStudentToParent(1L, 10L);

            assertThat(student.getParent()).isEqualTo(parent);
            assertThat(result.getParentId()).isEqualTo(10L);
            assertThat(result.getRole()).isEqualTo(Role.STUDENT);
        }

        @Test
        @DisplayName("should unlink a student when parentId is null")
        void unlinksStudentWhenParentIdIsNull() {
            Parent existingParent = new Parent();
            existingParent.setId(5L);

            Student student = new Student();
            student.setId(2L);
            student.setRole(Role.STUDENT);
            student.setParent(existingParent);

            when(userRepository.findById(2L)).thenReturn(Optional.of(student));
            when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

            UserSummaryResponse result = adminService.linkStudentToParent(2L, null);

            assertThat(student.getParent()).isNull();
            assertThat(result.getParentId()).isNull();
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when student not found")
        void throwsWhenStudentNotFound() {
            when(userRepository.findById(999L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> adminService.linkStudentToParent(999L, 10L))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(userRepository, never()).save(any(User.class));
        }

        @Test
        @DisplayName("should throw ResourceNotFoundException when parent not found")
        void throwsWhenParentNotFound() {
            Student student = new Student();
            student.setId(1L);
            student.setRole(Role.STUDENT);

            when(userRepository.findById(1L)).thenReturn(Optional.of(student));
            when(parentRepository.findById(999L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> adminService.linkStudentToParent(1L, 999L))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(userRepository, never()).save(any(User.class));
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
