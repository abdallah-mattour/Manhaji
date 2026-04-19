package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.AdminStatsResponse;
import com.springboot.manhaji.dto.response.UserSummaryResponse;
import com.springboot.manhaji.entity.Admin;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.Teacher;
import com.springboot.manhaji.entity.Attempt;
import com.springboot.manhaji.entity.Progress;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.repository.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;

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
    @Mock private AttemptRepository attemptRepository;
    @Mock private ProgressRepository progressRepository;

    @InjectMocks
    private AdminService adminService;

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
}
