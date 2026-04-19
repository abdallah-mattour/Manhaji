package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.AdminStatsResponse;
import com.springboot.manhaji.dto.response.UserSummaryResponse;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.User;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.repository.AdminRepository;
import com.springboot.manhaji.repository.AttemptRepository;
import com.springboot.manhaji.repository.LessonRepository;
import com.springboot.manhaji.repository.ParentRepository;
import com.springboot.manhaji.repository.ProgressRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import com.springboot.manhaji.repository.TeacherRepository;
import com.springboot.manhaji.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final ParentRepository parentRepository;
    private final AdminRepository adminRepository;
    private final SubjectRepository subjectRepository;
    private final LessonRepository lessonRepository;
    private final AttemptRepository attemptRepository;
    private final ProgressRepository progressRepository;

    public AdminStatsResponse getStats() {
        LocalDateTime weekAgo = LocalDateTime.now().minusDays(7);

        long activeThisWeek = studentRepository.findAll().stream()
                .filter(s -> s.getLastLoginAt() != null && s.getLastLoginAt().isAfter(weekAgo))
                .count();

        long completedAttempts = attemptRepository.findAll().stream()
                .filter(a -> a.getStatus() == AttemptStatus.GRADED)
                .count();

        long completedLessons = progressRepository.findAll().stream()
                .filter(p -> p.getCompletionStatus() == CompletionStatus.COMPLETED)
                .count();

        return AdminStatsResponse.builder()
                .totalStudents(studentRepository.count())
                .totalTeachers(teacherRepository.count())
                .totalParents(parentRepository.count())
                .totalAdmins(adminRepository.count())
                .totalSubjects(subjectRepository.count())
                .totalLessons(lessonRepository.count())
                .totalAttempts(completedAttempts)
                .totalCompletedLessons(completedLessons)
                .activeStudentsThisWeek(activeThisWeek)
                .build();
    }

    public List<UserSummaryResponse> getAllUsers(Role roleFilter) {
        List<User> users = userRepository.findAll();
        return users.stream()
                .filter(u -> roleFilter == null || u.getRole() == roleFilter)
                .map(this::toSummary)
                .toList();
    }

    private UserSummaryResponse toSummary(User user) {
        Integer gradeLevel = null;
        if (user instanceof Student student) {
            gradeLevel = student.getGradeLevel();
        }
        return UserSummaryResponse.builder()
                .userId(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .role(user.getRole())
                .isActive(user.getIsActive())
                .lastLoginAt(user.getLastLoginAt())
                .createdAt(user.getCreatedAt())
                .gradeLevel(gradeLevel)
                .build();
    }
}
