package com.springboot.manhaji.service;

import com.springboot.manhaji.config.JwtService;
import com.springboot.manhaji.dto.request.LoginRequest;
import com.springboot.manhaji.dto.request.PhoneLoginRequest;
import com.springboot.manhaji.dto.request.RegisterRequest;
import com.springboot.manhaji.dto.response.AuthResponse;
import com.springboot.manhaji.entity.Admin;
import com.springboot.manhaji.entity.Parent;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.Teacher;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.exception.BadRequestException;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.exception.UnauthorizedException;
import com.springboot.manhaji.repository.UserRepository;
import com.springboot.manhaji.support.TestMessages;
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
                    .isInstanceOf(UnauthorizedException.class);
        }

        @Test
        @DisplayName("should reject non-existent email")
        void loginNonExistentEmail() {
            LoginRequest request = new LoginRequest();
            request.setEmail("nobody@test.com");
            request.setPassword("pass");

            when(userRepository.findByEmail("nobody@test.com")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> authService.loginWithEmail(request))
                    .isInstanceOf(UnauthorizedException.class);
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
                    .isInstanceOf(UnauthorizedException.class)
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
                    .isInstanceOf(UnauthorizedException.class);
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
                    .isInstanceOf(UnauthorizedException.class)
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
                    .isInstanceOf(UnauthorizedException.class);
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
                    .isInstanceOf(UnauthorizedException.class)
                    .hasMessageContaining("disabled");
            verify(jwtService, never()).generateAccessToken(any());
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
    }
}
