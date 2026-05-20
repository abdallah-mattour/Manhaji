package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.request.AdminCreateUserRequest;
import com.springboot.manhaji.dto.request.AdminUpdateUserRequest;
import com.springboot.manhaji.dto.response.AdminStatsResponse;
import com.springboot.manhaji.dto.response.LessonSummary;
import com.springboot.manhaji.dto.response.QuestionBankItem;
import com.springboot.manhaji.dto.response.QuestionBankResponse;
import com.springboot.manhaji.dto.response.SubjectSummary;
import com.springboot.manhaji.dto.response.UserSummaryResponse;
import com.springboot.manhaji.entity.Question;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.Teacher;
import com.springboot.manhaji.entity.User;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.exception.BadRequestException;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.infrastructure.Messages;
import com.springboot.manhaji.repository.AdminRepository;
import com.springboot.manhaji.repository.AttemptRepository;
import com.springboot.manhaji.repository.LessonRepository;
import com.springboot.manhaji.repository.ParentRepository;
import com.springboot.manhaji.repository.ProgressRepository;
import com.springboot.manhaji.repository.QuestionRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import com.springboot.manhaji.repository.TeacherRepository;
import com.springboot.manhaji.repository.UserRepository;
import com.springboot.manhaji.service.support.QuestionBankMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminService {

    /**
     * Roles the admin CRUD surface is allowed to manage. Admin and Parent are
     * intentionally excluded — admins are managed via DB seeding, parents via
     * the public self-registration flow.
     */
    private static final Set<Role> MANAGEABLE_ROLES = EnumSet.of(Role.STUDENT, Role.TEACHER);

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final ParentRepository parentRepository;
    private final AdminRepository adminRepository;
    private final SubjectRepository subjectRepository;
    private final LessonRepository lessonRepository;
    private final QuestionRepository questionRepository;
    private final AttemptRepository attemptRepository;
    private final ProgressRepository progressRepository;
    private final QuestionBankMapper questionBankMapper;
    private final PasswordEncoder passwordEncoder;
    private final Messages messages;

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

    // ==================== CRUD (Students + Teachers) ====================

    @Transactional
    public UserSummaryResponse createUser(AdminCreateUserRequest request) {
        Role role = request.getRole();
        if (role == null || !MANAGEABLE_ROLES.contains(role)) {
            throw new BadRequestException(messages.get(
                    "error.admin.roleNotManageable", role == null ? "null" : role.name()));
        }
        if (request.getEmail() == null && request.getPhone() == null) {
            throw new BadRequestException(messages.get("error.admin.emailOrPhoneRequired"));
        }
        if (request.getEmail() != null && userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException(messages.get("error.auth.emailAlreadyRegistered"));
        }
        if (request.getPhone() != null && userRepository.existsByPhone(request.getPhone())) {
            throw new BadRequestException(messages.get("error.auth.phoneAlreadyRegistered"));
        }

        User user = switch (role) {
            case STUDENT -> {
                if (request.getGradeLevel() == null) {
                    throw new BadRequestException(messages.get("error.admin.studentGradeRequired"));
                }
                Student student = new Student();
                student.setGradeLevel(request.getGradeLevel());
                yield student;
            }
            case TEACHER -> {
                Teacher teacher = new Teacher();
                teacher.setDepartment(request.getDepartment());
                teacher.setAssignedGrade(request.getAssignedGrade());
                yield teacher;
            }
            default -> throw new BadRequestException(messages.get(
                    "error.admin.roleNotManageable", role.name()));
        };
        user.setRole(role);
        user.setFullName(request.getFullName());
        user.setEmail(request.getEmail());
        user.setPhone(request.getPhone());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setIsActive(true);

        User saved = userRepository.save(user);
        return toSummary(saved);
    }

    @Transactional
    public UserSummaryResponse updateUser(Long userId, AdminUpdateUserRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));
        if (!MANAGEABLE_ROLES.contains(user.getRole())) {
            throw new BadRequestException(messages.get(
                    "error.admin.roleNotManageable", user.getRole().name()));
        }

        if (request.getFullName() != null && !request.getFullName().isBlank()) {
            user.setFullName(request.getFullName());
        }
        if (request.getEmail() != null && !request.getEmail().equals(user.getEmail())) {
            if (userRepository.existsByEmail(request.getEmail())) {
                throw new BadRequestException(messages.get("error.auth.emailAlreadyRegistered"));
            }
            user.setEmail(request.getEmail());
        }
        if (request.getPhone() != null && !request.getPhone().equals(user.getPhone())) {
            if (userRepository.existsByPhone(request.getPhone())) {
                throw new BadRequestException(messages.get("error.auth.phoneAlreadyRegistered"));
            }
            user.setPhone(request.getPhone());
        }
        if (request.getPassword() != null && !request.getPassword().isBlank()) {
            user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        }
        if (request.getIsActive() != null) {
            user.setIsActive(request.getIsActive());
        }
        if (user instanceof Student student) {
            if (request.getGradeLevel() != null) {
                student.setGradeLevel(request.getGradeLevel());
            }
        }
        if (user instanceof Teacher teacher) {
            if (request.getDepartment() != null) {
                teacher.setDepartment(request.getDepartment());
            }
            if (request.getAssignedGrade() != null) {
                teacher.setAssignedGrade(request.getAssignedGrade());
            }
        }

        User saved = userRepository.save(user);
        return toSummary(saved);
    }

    @Transactional
    public void deleteUser(Long userId, Long callerUserId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));
        if (!MANAGEABLE_ROLES.contains(user.getRole())) {
            throw new BadRequestException(messages.get(
                    "error.admin.roleNotManageable", user.getRole().name()));
        }
        if (callerUserId != null && callerUserId.equals(userId)) {
            throw new BadRequestException(messages.get("error.admin.cannotDeleteSelf"));
        }
        userRepository.delete(user);
    }

    // ==================== Question Bank (FR-9, unrestricted — admin sees all) ====================

    public List<SubjectSummary> getAllSubjects(Integer gradeFilter) {
        List<Subject> subjects = gradeFilter != null
                ? subjectRepository.findByGradeLevel(gradeFilter)
                : subjectRepository.findAll();
        return subjects.stream()
                .sorted(Comparator
                        .comparing(Subject::getGradeLevel,
                                Comparator.nullsLast(Comparator.naturalOrder()))
                        .thenComparing(Subject::getName,
                                Comparator.nullsLast(Comparator.naturalOrder())))
                .map(questionBankMapper::toSubjectSummary)
                .toList();
    }

    public QuestionBankResponse getQuestionsForSubject(
            Long subjectId,
            Integer difficultyLevel,
            Long lessonId) {
        Subject subject = subjectRepository.findById(subjectId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject", subjectId));

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
