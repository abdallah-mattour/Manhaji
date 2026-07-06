package com.springboot.manhaji.service;

import com.springboot.manhaji.config.JwtService;
import com.springboot.manhaji.dto.request.LoginRequest;
import com.springboot.manhaji.dto.request.PhoneLoginRequest;
import com.springboot.manhaji.dto.request.RegisterRequest;
import com.springboot.manhaji.dto.request.UpdateProfileRequest;
import com.springboot.manhaji.dto.response.AuthResponse;
import com.springboot.manhaji.entity.Admin;
import com.springboot.manhaji.entity.Parent;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.Teacher;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.exception.AuthenticationFailedException;
import com.springboot.manhaji.exception.BadRequestException;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.repository.UserRepository;
import com.springboot.manhaji.infrastructure.TestMessages;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    private AuthService authService;

    @BeforeEach
    void initService() {
        authService = new AuthService(userRepository, passwordEncoder, jwtService, TestMessages.create());
    }

    // ==================== Registration Tests ====================

    @Nested
    @DisplayName("register()")
    class RegisterTests {

        @Test
        @DisplayName("should register a student with email successfully")
        void registerStudentWithEmail() {
            RegisterRequest request = new RegisterRequest();
            request.setFullName("طالب جديد");
            request.setEmail("student@test.com");
            request.setPassword("pass123");
            request.setRole(Role.STUDENT);
            request.setGradeLevel(1);

            when(userRepository.existsByEmail("student@test.com")).thenReturn(false);
            when(passwordEncoder.encode("pass123")).thenReturn("hashed_pass");
            when(userRepository.save(any())).thenAnswer(inv -> {
                Student s = (Student) inv.getArgument(0);
                s.setId(1L);
                return s;
            });
            when(userRepository.findById(1L)).thenAnswer(inv -> {
                Student s = new Student();
                s.setId(1L);
                s.setFullName("طالب جديد");
                s.setEmail("student@test.com");
                s.setRole(Role.STUDENT);
                s.setGradeLevel(1);
                return Optional.of(s);
            });
            when(jwtService.generateAccessToken(any())).thenReturn("access_token");
            when(jwtService.generateRefreshToken(any())).thenReturn("refresh_token");

            AuthResponse response = authService.register(request);

            assertThat(response.getAccessToken()).isEqualTo("access_token");
            assertThat(response.getRefreshToken()).isEqualTo("refresh_token");
            assertThat(response.getUserId()).isEqualTo(1L);
            assertThat(response.getFullName()).isEqualTo("طالب جديد");
            assertThat(response.getRole()).isEqualTo(Role.STUDENT);
            assertThat(response.getGradeLevel()).isEqualTo(1);
        }

        @Test
        @DisplayName("audit C1 regression: public registration rejects TEACHER role")
        void rejectsPublicTeacherRegistration() {
            // Audit-4 fix C1: only STUDENT and PARENT may self-register.
            // Teachers must be created via the admin-protected flow.
            RegisterRequest request = new RegisterRequest();
            request.setFullName("معلم جديد");
            request.setEmail("teacher@test.com");
            request.setPassword("pass123");
            request.setRole(Role.TEACHER);

            assertThatThrownBy(() -> authService.register(request))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("Invalid role");
            verifyNoInteractions(userRepository, passwordEncoder, jwtService);
        }

        @Test
        @DisplayName("audit C1 regression: public registration rejects ADMIN role (privilege escalation)")
        void rejectsPublicAdminRegistration() {
            // Audit-4 fix C1: an anonymous attacker used to be able to mint
            // an admin token by setting role=ADMIN in the register payload.
            RegisterRequest request = new RegisterRequest();
            request.setFullName("evil");
            request.setEmail("attacker@example.com");
            request.setPassword("pass123");
            request.setRole(Role.ADMIN);

            assertThatThrownBy(() -> authService.register(request))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("Invalid role");
            verifyNoInteractions(userRepository, passwordEncoder, jwtService);
        }

        @Test
        @DisplayName("should reject duplicate email")
        void rejectDuplicateEmail() {
            RegisterRequest request = new RegisterRequest();
            request.setEmail("taken@test.com");
            request.setPassword("pass123");
            request.setRole(Role.STUDENT);
            request.setFullName("Test");
            request.setGradeLevel(1);

            when(userRepository.existsByEmail("taken@test.com")).thenReturn(true);

            assertThatThrownBy(() -> authService.register(request))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("Email already registered");
        }

        @Test
        @DisplayName("should reject duplicate phone")
        void rejectDuplicatePhone() {
            RegisterRequest request = new RegisterRequest();
            request.setPhone("0591234567");
            request.setPassword("pass123");
            request.setRole(Role.STUDENT);
            request.setFullName("Test");
            request.setGradeLevel(1);

            when(userRepository.existsByPhone("0591234567")).thenReturn(true);

            assertThatThrownBy(() -> authService.register(request))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("Phone number already registered");
        }

        @Test
        @DisplayName("should reject registration without email or phone")
        void rejectNoEmailNoPhone() {
            RegisterRequest request = new RegisterRequest();
            request.setPassword("pass123");
            request.setRole(Role.STUDENT);
            request.setFullName("Test");
            request.setGradeLevel(1);

            assertThatThrownBy(() -> authService.register(request))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("Email or phone number is required");
        }

        @Test
        @DisplayName("should hash password before saving")
        void shouldHashPassword() {
            RegisterRequest request = new RegisterRequest();
            request.setFullName("Test");
            request.setEmail("test@test.com");
            request.setPassword("plain_password");
            request.setRole(Role.PARENT);

            when(userRepository.existsByEmail(anyString())).thenReturn(false);
            when(passwordEncoder.encode("plain_password")).thenReturn("hashed_password");
            when(userRepository.save(any())).thenAnswer(inv -> {
                Parent p = (Parent) inv.getArgument(0);
                p.setId(3L);
                return p;
            });
            when(userRepository.findById(3L)).thenAnswer(inv -> {
                Parent p = new Parent();
                p.setId(3L);
                p.setFullName("Test");
                p.setRole(Role.PARENT);
                return Optional.of(p);
            });
            when(jwtService.generateAccessToken(any())).thenReturn("at");
            when(jwtService.generateRefreshToken(any())).thenReturn("rt");

            authService.register(request);

            ArgumentCaptor<Parent> captor = ArgumentCaptor.forClass(Parent.class);
            verify(userRepository).save(captor.capture());
            assertThat(captor.getValue().getPasswordHash()).isEqualTo("hashed_password");
        }

        @Test
        @DisplayName("should reject student with null gradeLevel")
        void rejectStudentWithNullGradeLevel() {
            RegisterRequest request = new RegisterRequest();
            request.setFullName("طالب");
            request.setEmail("student@test.com");
            request.setPassword("pass123");
            request.setRole(Role.STUDENT);
            // gradeLevel left null — validation must fire before any repository call

            assertThatThrownBy(() -> authService.register(request))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("يجب تحديد الصف الدراسي");
            verifyNoInteractions(userRepository, passwordEncoder, jwtService);
        }

        @Test
        @DisplayName("should reject student with gradeLevel 0 (below minimum)")
        void rejectStudentWithGradeLevelZero() {
            RegisterRequest request = new RegisterRequest();
            request.setFullName("طالب");
            request.setEmail("student@test.com");
            request.setPassword("pass123");
            request.setRole(Role.STUDENT);
            request.setGradeLevel(0);

            assertThatThrownBy(() -> authService.register(request))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("يجب أن يكون بين 1 و 4");
            verifyNoInteractions(userRepository, passwordEncoder, jwtService);
        }

        @Test
        @DisplayName("should reject student with gradeLevel 5 (above maximum)")
        void rejectStudentWithGradeLevelTooHigh() {
            RegisterRequest request = new RegisterRequest();
            request.setFullName("طالب");
            request.setEmail("student@test.com");
            request.setPassword("pass123");
            request.setRole(Role.STUDENT);
            request.setGradeLevel(5);

            assertThatThrownBy(() -> authService.register(request))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("يجب أن يكون بين 1 و 4");
            verifyNoInteractions(userRepository, passwordEncoder, jwtService);
        }

        @Test
        @DisplayName("parent registration succeeds without gradeLevel")
        void parentRegistrationDoesNotRequireGradeLevel() {
            RegisterRequest request = new RegisterRequest();
            request.setFullName("ولي أمر");
            request.setEmail("parent@test.com");
            request.setPassword("pass123");
            request.setRole(Role.PARENT);
            // gradeLevel not set — must not be required for non-student roles

            when(userRepository.existsByEmail("parent@test.com")).thenReturn(false);
            when(passwordEncoder.encode("pass123")).thenReturn("hashed");
            when(userRepository.save(any())).thenAnswer(inv -> {
                Parent p = (Parent) inv.getArgument(0);
                p.setId(10L);
                return p;
            });
            when(userRepository.findById(10L)).thenAnswer(inv -> {
                Parent p = new Parent();
                p.setId(10L);
                p.setFullName("ولي أمر");
                p.setEmail("parent@test.com");
                p.setRole(Role.PARENT);
                return Optional.of(p);
            });
            when(jwtService.generateAccessToken(any())).thenReturn("access_token");
            when(jwtService.generateRefreshToken(any())).thenReturn("refresh_token");

            AuthResponse response = authService.register(request);

            assertThat(response.getUserId()).isEqualTo(10L);
            assertThat(response.getRole()).isEqualTo(Role.PARENT);
            assertThat(response.getGradeLevel()).isNull();
        }
    }

    // ==================== Login Tests ====================

    @Nested
    @DisplayName("loginWithEmail()")
    class LoginWithEmailTests {

        @Test
        @DisplayName("should login with correct email and password")
        void loginSuccess() {
            LoginRequest request = new LoginRequest();
            request.setEmail("user@test.com");
            request.setPassword("correct_pass");

            Student student = new Student();
            student.setId(1L);
            student.setEmail("user@test.com");
            student.setPasswordHash("hashed_pass");
            student.setFullName("طالب");
            student.setRole(Role.STUDENT);
            student.setGradeLevel(1);

            when(userRepository.findByEmail("user@test.com")).thenReturn(Optional.of(student));
            when(passwordEncoder.matches("correct_pass", "hashed_pass")).thenReturn(true);
            when(userRepository.save(any())).thenReturn(student);
            when(jwtService.generateAccessToken(student)).thenReturn("access");
            when(jwtService.generateRefreshToken(student)).thenReturn("refresh");

            AuthResponse response = authService.loginWithEmail(request);

            assertThat(response.getAccessToken()).isEqualTo("access");
            assertThat(response.getUserId()).isEqualTo(1L);
            verify(userRepository).save(student); // should update lastLoginAt
        }

        @Test
        @DisplayName("should reject wrong password")
        void loginWrongPassword() {
            LoginRequest request = new LoginRequest();
            request.setEmail("user@test.com");
            request.setPassword("wrong_pass");

            Student student = new Student();
            student.setPasswordHash("hashed_pass");

            when(userRepository.findByEmail("user@test.com")).thenReturn(Optional.of(student));
            when(passwordEncoder.matches("wrong_pass", "hashed_pass")).thenReturn(false);

            assertThatThrownBy(() -> authService.loginWithEmail(request))
                    .isInstanceOf(AuthenticationFailedException.class);
        }

        @Test
        @DisplayName("should reject non-existent email")
        void loginNonExistentEmail() {
            LoginRequest request = new LoginRequest();
            request.setEmail("nobody@test.com");
            request.setPassword("pass");

            when(userRepository.findByEmail("nobody@test.com")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> authService.loginWithEmail(request))
                    .isInstanceOf(AuthenticationFailedException.class);
        }

        @Test
        @DisplayName("audit H1 regression: disabled account is rejected even with correct password")
        void rejectsDisabledAccount() {
            // Audit-4 fix H1: isActive=false used to be ignored by login.
            LoginRequest request = new LoginRequest();
            request.setEmail("disabled@test.com");
            request.setPassword("correct_pass");

            Student disabled = new Student();
            disabled.setId(99L);
            disabled.setEmail("disabled@test.com");
            disabled.setPasswordHash("hashed_pass");
            disabled.setIsActive(false);
            disabled.setRole(Role.STUDENT);

            when(userRepository.findByEmail("disabled@test.com")).thenReturn(Optional.of(disabled));
            when(passwordEncoder.matches("correct_pass", "hashed_pass")).thenReturn(true);

            assertThatThrownBy(() -> authService.loginWithEmail(request))
                    .isInstanceOf(AuthenticationFailedException.class)
                    .hasMessageContaining("disabled");
            // Critical: no tokens minted, no save called.
            verify(jwtService, never()).generateAccessToken(any());
            verify(userRepository, never()).save(any());
        }
    }

    // ==================== Phone Login Tests ====================

    @Nested
    @DisplayName("loginWithPhone()")
    class LoginWithPhoneTests {

        @Test
        @DisplayName("should login with correct phone and password")
        void phoneLoginSuccess() {
            PhoneLoginRequest request = new PhoneLoginRequest();
            request.setPhone("0591234567");
            request.setPassword("pass");

            Student student = new Student();
            student.setId(5L);
            student.setPhone("0591234567");
            student.setPasswordHash("hashed");
            student.setFullName("طالب");
            student.setRole(Role.STUDENT);

            when(userRepository.findByPhone("0591234567")).thenReturn(Optional.of(student));
            when(passwordEncoder.matches("pass", "hashed")).thenReturn(true);
            when(userRepository.save(any())).thenReturn(student);
            when(jwtService.generateAccessToken(any())).thenReturn("at");
            when(jwtService.generateRefreshToken(any())).thenReturn("rt");

            AuthResponse response = authService.loginWithPhone(request);

            assertThat(response.getUserId()).isEqualTo(5L);
        }

        @Test
        @DisplayName("should reject non-existent phone number")
        void phoneLoginNotFound() {
            PhoneLoginRequest request = new PhoneLoginRequest();
            request.setPhone("0000000000");
            request.setPassword("pass");

            when(userRepository.findByPhone("0000000000")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> authService.loginWithPhone(request))
                    .isInstanceOf(AuthenticationFailedException.class);
        }
    }

    // ==================== Token Refresh Tests ====================

    @Nested
    @DisplayName("refreshToken()")
    class RefreshTokenTests {

        @Test
        @DisplayName("should refresh with valid token")
        void refreshSuccess() {
            // Audit-4 fix C5: refresh now requires isRefreshToken() (type-checked).
            when(jwtService.isRefreshToken("valid_refresh")).thenReturn(true);
            when(jwtService.extractSubject("valid_refresh")).thenReturn("user@test.com");

            Student student = new Student();
            student.setId(1L);
            student.setEmail("user@test.com");
            student.setRole(Role.STUDENT);
            student.setFullName("Test");
            student.setIsActive(true); // Audit-4 fix H1: refresh also blocks disabled users.

            when(userRepository.findByEmail("user@test.com")).thenReturn(Optional.of(student));
            when(jwtService.generateAccessToken(student)).thenReturn("new_access");
            when(jwtService.generateRefreshToken(student)).thenReturn("new_refresh");

            AuthResponse response = authService.refreshToken("valid_refresh");

            assertThat(response.getAccessToken()).isEqualTo("new_access");
            assertThat(response.getRefreshToken()).isEqualTo("new_refresh");
        }

        @Test
        @DisplayName("should reject expired token")
        void refreshExpiredToken() {
            when(jwtService.isRefreshToken("expired_token")).thenReturn(false);

            assertThatThrownBy(() -> authService.refreshToken("expired_token"))
                    .isInstanceOf(AuthenticationFailedException.class)
                    .hasMessageContaining("Invalid or expired refresh token");
        }

        @Test
        @DisplayName("audit C5 regression: access token rejected on refresh endpoint")
        void rejectsAccessTokenAtRefresh() {
            // Audit-4 fix C5: previously, an access token could be replayed
            // at /api/auth/refresh because the validity check didn't
            // distinguish token types.
            when(jwtService.isRefreshToken("access_token_replayed")).thenReturn(false);

            assertThatThrownBy(() -> authService.refreshToken("access_token_replayed"))
                    .isInstanceOf(AuthenticationFailedException.class);
            verify(userRepository, never()).findByEmail(any());
        }

        @Test
        @DisplayName("audit H1 regression: refresh path also blocks disabled accounts")
        void rejectsRefreshForDisabledAccount() {
            when(jwtService.isRefreshToken("valid_refresh")).thenReturn(true);
            when(jwtService.extractSubject("valid_refresh")).thenReturn("disabled@test.com");

            Student disabled = new Student();
            disabled.setId(11L);
            disabled.setEmail("disabled@test.com");
            disabled.setIsActive(false);
            disabled.setRole(Role.STUDENT);
            when(userRepository.findByEmail("disabled@test.com")).thenReturn(Optional.of(disabled));

            assertThatThrownBy(() -> authService.refreshToken("valid_refresh"))
                    .isInstanceOf(AuthenticationFailedException.class)
                    .hasMessageContaining("disabled");
            verify(jwtService, never()).generateAccessToken(any());
        }
    }

    // ==================== Change Password Tests ====================

    @Nested
    @DisplayName("changePassword()")
    class ChangePasswordTests {

        @Test
        @DisplayName("should change password when current password is correct")
        void changePasswordSuccess() {
            Student student = new Student();
            student.setId(1L);
            student.setPasswordHash("hashed_old");
            student.setRole(Role.STUDENT);

            when(userRepository.findById(1L)).thenReturn(Optional.of(student));
            when(passwordEncoder.matches("old_pass", "hashed_old")).thenReturn(true);
            when(passwordEncoder.encode("new_pass123")).thenReturn("hashed_new");
            when(userRepository.save(any())).thenReturn(student);

            authService.changePassword(1L, "old_pass", "new_pass123");

            ArgumentCaptor<Student> captor = ArgumentCaptor.forClass(Student.class);
            verify(userRepository).save(captor.capture());
            assertThat(captor.getValue().getPasswordHash()).isEqualTo("hashed_new");
        }

        @Test
        @DisplayName("should save encoded hash, not plaintext new password")
        void savedPasswordIsEncoded() {
            Student student = new Student();
            student.setId(2L);
            student.setPasswordHash("hashed_old");

            when(userRepository.findById(2L)).thenReturn(Optional.of(student));
            when(passwordEncoder.matches("old", "hashed_old")).thenReturn(true);
            when(passwordEncoder.encode("brand_new")).thenReturn("$2a$10$fakeHashedValue");
            when(userRepository.save(any())).thenReturn(student);

            authService.changePassword(2L, "old", "brand_new");

            ArgumentCaptor<Student> captor = ArgumentCaptor.forClass(Student.class);
            verify(userRepository).save(captor.capture());
            // Must be encoded value, never the plaintext
            assertThat(captor.getValue().getPasswordHash()).isNotEqualTo("brand_new");
            assertThat(captor.getValue().getPasswordHash()).isEqualTo("$2a$10$fakeHashedValue");
        }

        @Test
        @DisplayName("should reject wrong current password")
        void changePasswordWrongCurrent() {
            Student student = new Student();
            student.setId(3L);
            student.setPasswordHash("hashed_old");

            when(userRepository.findById(3L)).thenReturn(Optional.of(student));
            when(passwordEncoder.matches("wrong_pass", "hashed_old")).thenReturn(false);

            assertThatThrownBy(() -> authService.changePassword(3L, "wrong_pass", "new_pass123"))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("كلمة المرور الحالية غير صحيحة");
            verify(userRepository, never()).save(any());
        }

        @Test
        @DisplayName("should reject when new password equals current password")
        void changePasswordSamePassword() {
            Student student = new Student();
            student.setId(4L);
            student.setPasswordHash("hashed_pass");

            when(userRepository.findById(4L)).thenReturn(Optional.of(student));
            when(passwordEncoder.matches("same_pass", "hashed_pass")).thenReturn(true);

            assertThatThrownBy(() -> authService.changePassword(4L, "same_pass", "same_pass"))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("يجب أن تختلف");
            verify(userRepository, never()).save(any());
        }

        @Test
        @DisplayName("should throw when user not found")
        void changePasswordUserNotFound() {
            when(userRepository.findById(999L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> authService.changePassword(999L, "any_pass", "new_pass123"))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(passwordEncoder, never()).matches(any(), any());
            verify(userRepository, never()).save(any());
        }
    }

    // ==================== Update Profile Tests ====================

    @Nested
    @DisplayName("updateProfile()")
    class UpdateProfileTests {

        @Test
        @DisplayName("should update fullName when provided")
        void updateFullName() {
            Student student = new Student();
            student.setId(1L);
            student.setFullName("اسم قديم");
            student.setEmail("user@test.com");
            student.setRole(Role.STUDENT);
            student.setGradeLevel(1);

            when(userRepository.findById(1L)).thenReturn(Optional.of(student));
            when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            UpdateProfileRequest request = new UpdateProfileRequest();
            request.setFullName("اسم جديد");

            AuthResponse response = authService.updateProfile(1L, request);

            assertThat(response.getFullName()).isEqualTo("اسم جديد");
            verify(userRepository).save(argThat(u -> "اسم جديد".equals(u.getFullName())));
        }

        @Test
        @DisplayName("should update student avatarId when provided")
        void updateStudentAvatarId() {
            Student student = new Student();
            student.setId(11L);
            student.setFullName("طالبة");
            student.setEmail("student-avatar@test.com");
            student.setRole(Role.STUDENT);
            student.setGradeLevel(2);

            when(userRepository.findById(11L)).thenReturn(Optional.of(student));
            when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            UpdateProfileRequest request = new UpdateProfileRequest();
            request.setFullName("طالبة");
            request.setAvatarId("avatar-book");

            AuthResponse response = authService.updateProfile(11L, request);

            assertThat(response.getAvatarId()).isEqualTo("avatar-book");
            assertThat(response.getGradeLevel()).isEqualTo(2);
            verify(userRepository).save(argThat(u ->
                    u instanceof Student saved && "avatar-book".equals(saved.getAvatarId())));
        }

        @Test
        @DisplayName("should update teacher avatarId without changing role")
        void updateTeacherAvatarId() {
            Teacher teacher = new Teacher();
            teacher.setId(12L);
            teacher.setFullName("معلمة");
            teacher.setEmail("teacher-avatar@test.com");
            teacher.setRole(Role.TEACHER);

            when(userRepository.findById(12L)).thenReturn(Optional.of(teacher));
            when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            UpdateProfileRequest request = new UpdateProfileRequest();
            request.setAvatarId("avatar-star");

            AuthResponse response = authService.updateProfile(12L, request);

            assertThat(response.getRole()).isEqualTo(Role.TEACHER);
            assertThat(response.getAvatarId()).isEqualTo("avatar-star");
            verify(userRepository).save(argThat(u ->
                    u instanceof Teacher saved && "avatar-star".equals(saved.getAvatarId())));
        }

        @Test
        @DisplayName("blank avatarId clears safely to null")
        void blankAvatarClearsToNull() {
            Parent parent = new Parent();
            parent.setId(13L);
            parent.setFullName("ولي أمر");
            parent.setEmail("parent-avatar@test.com");
            parent.setRole(Role.PARENT);
            parent.setAvatarId("avatar-old");

            when(userRepository.findById(13L)).thenReturn(Optional.of(parent));
            when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            UpdateProfileRequest request = new UpdateProfileRequest();
            request.setAvatarId("   ");

            AuthResponse response = authService.updateProfile(13L, request);

            assertThat(response.getAvatarId()).isNull();
            verify(userRepository).save(argThat(u ->
                    u instanceof Parent saved && saved.getAvatarId() == null));
        }

        @Test
        @DisplayName("should update email when provided and not a duplicate")
        void updateEmail() {
            Student student = new Student();
            student.setId(2L);
            student.setFullName("طالب");
            student.setEmail("old@test.com");
            student.setRole(Role.STUDENT);

            when(userRepository.findById(2L)).thenReturn(Optional.of(student));
            when(userRepository.existsByEmail("new@test.com")).thenReturn(false);
            when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            UpdateProfileRequest request = new UpdateProfileRequest();
            request.setEmail("new@test.com");

            AuthResponse response = authService.updateProfile(2L, request);

            assertThat(response.getEmail()).isEqualTo("new@test.com");
            verify(userRepository).existsByEmail("new@test.com");
        }

        @Test
        @DisplayName("should update phone when provided and not a duplicate")
        void updatePhone() {
            Student student = new Student();
            student.setId(3L);
            student.setFullName("طالب");
            student.setPhone("0591111111");
            student.setRole(Role.STUDENT);

            when(userRepository.findById(3L)).thenReturn(Optional.of(student));
            when(userRepository.existsByPhone("0592222222")).thenReturn(false);
            when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            UpdateProfileRequest request = new UpdateProfileRequest();
            request.setPhone("0592222222");

            AuthResponse response = authService.updateProfile(3L, request);

            assertThat(response.getPhone()).isEqualTo("0592222222");
            verify(userRepository).existsByPhone("0592222222");
        }

        @Test
        @DisplayName("should skip uniqueness check when email is unchanged")
        void sameEmailSkipsUniquenessCheck() {
            Student student = new Student();
            student.setId(4L);
            student.setEmail("same@test.com");
            student.setFullName("طالب");
            student.setRole(Role.STUDENT);

            when(userRepository.findById(4L)).thenReturn(Optional.of(student));
            when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            UpdateProfileRequest request = new UpdateProfileRequest();
            request.setEmail("same@test.com");

            authService.updateProfile(4L, request);

            verify(userRepository, never()).existsByEmail(any());
        }

        @Test
        @DisplayName("should reject duplicate email belonging to another user")
        void duplicateEmailRejected() {
            Student student = new Student();
            student.setId(5L);
            student.setEmail("mine@test.com");
            student.setFullName("طالب");
            student.setRole(Role.STUDENT);

            when(userRepository.findById(5L)).thenReturn(Optional.of(student));
            when(userRepository.existsByEmail("taken@test.com")).thenReturn(true);

            UpdateProfileRequest request = new UpdateProfileRequest();
            request.setEmail("taken@test.com");

            assertThatThrownBy(() -> authService.updateProfile(5L, request))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("Email already registered");
            verify(userRepository, never()).save(any());
        }

        @Test
        @DisplayName("should reject duplicate phone belonging to another user")
        void duplicatePhoneRejected() {
            Student student = new Student();
            student.setId(6L);
            student.setPhone("0591111111");
            student.setFullName("طالب");
            student.setRole(Role.STUDENT);

            when(userRepository.findById(6L)).thenReturn(Optional.of(student));
            when(userRepository.existsByPhone("0599999999")).thenReturn(true);

            UpdateProfileRequest request = new UpdateProfileRequest();
            request.setPhone("0599999999");

            assertThatThrownBy(() -> authService.updateProfile(6L, request))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("Phone number already registered");
            verify(userRepository, never()).save(any());
        }

        @Test
        @DisplayName("should throw when user not found")
        void userNotFound() {
            when(userRepository.findById(999L)).thenReturn(Optional.empty());

            UpdateProfileRequest request = new UpdateProfileRequest();
            request.setFullName("اسم");

            assertThatThrownBy(() -> authService.updateProfile(999L, request))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(userRepository, never()).existsByEmail(any());
            verify(userRepository, never()).save(any());
        }
    }

    // ==================== getCurrentUser Tests ====================

    @Nested
    @DisplayName("getCurrentUser()")
    class GetCurrentUserTests {

        @Test
        @DisplayName("should return user by id")
        void getUserSuccess() {
            Student student = new Student();
            student.setId(1L);
            student.setFullName("طالب");

            when(userRepository.findById(1L)).thenReturn(Optional.of(student));

            var user = authService.getCurrentUser(1L);
            assertThat(user.getFullName()).isEqualTo("طالب");
        }

        @Test
        @DisplayName("should throw when user not found")
        void getUserNotFound() {
            when(userRepository.findById(999L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> authService.getCurrentUser(999L))
                    .isInstanceOf(ResourceNotFoundException.class);
        }

        @Test
        @DisplayName("getCurrentProfile includes avatarId for existing users")
        void getCurrentProfileIncludesAvatarId() {
            Teacher teacher = new Teacher();
            teacher.setId(2L);
            teacher.setFullName("معلم");
            teacher.setEmail("teacher@test.com");
            teacher.setRole(Role.TEACHER);
            teacher.setAvatarId("avatar-olive");

            when(userRepository.findById(2L)).thenReturn(Optional.of(teacher));

            AuthResponse response = authService.getCurrentProfile(2L);

            assertThat(response.getFullName()).isEqualTo("معلم");
            assertThat(response.getAvatarId()).isEqualTo("avatar-olive");
            assertThat(response.getAccessToken()).isNull();
            assertThat(response.getRefreshToken()).isNull();
        }
    }
}
