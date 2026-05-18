package com.springboot.manhaji.service;

import com.springboot.manhaji.config.JwtService;
import com.springboot.manhaji.dto.request.LoginRequest;
import com.springboot.manhaji.dto.request.PhoneLoginRequest;
import com.springboot.manhaji.dto.request.RegisterRequest;
import com.springboot.manhaji.dto.response.AuthResponse;
import com.springboot.manhaji.entity.*;
import com.springboot.manhaji.exception.BadRequestException;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.exception.UnauthorizedException;
import com.springboot.manhaji.repository.UserRepository;
import com.springboot.manhaji.infrastructure.Messages;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final Messages messages;

    /**
     * Roles that are allowed to self-register via the public
     * {@code /api/auth/register} endpoint. Audit-4 fix (2026-05-15): the
     * original code accepted any role from the request body, including
     * {@code ADMIN}, which let an anonymous attacker mint a privileged token.
     *
     * <p>Teachers and admins must be created via the admin-protected
     * {@code /api/admin/...} flow.
     */
    private static final java.util.Set<com.springboot.manhaji.entity.enums.Role> PUBLIC_REGISTRATION_ROLES =
            java.util.Set.of(
                    com.springboot.manhaji.entity.enums.Role.STUDENT,
                    com.springboot.manhaji.entity.enums.Role.PARENT
            );

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        // Audit-4 fix C1 (2026-05-15): reject privileged self-registration up
        // front, before any DB hit, before any user mutation.
        if (request.getRole() == null || !PUBLIC_REGISTRATION_ROLES.contains(request.getRole())) {
            throw new BadRequestException(messages.get("error.auth.invalidRole",
                    request.getRole() == null ? "null" : request.getRole().name()));
        }

        if (request.getEmail() != null && userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException(messages.get("error.auth.emailAlreadyRegistered"));
        }
        if (request.getPhone() != null && userRepository.existsByPhone(request.getPhone())) {
            throw new BadRequestException(messages.get("error.auth.phoneAlreadyRegistered"));
        }
        if (request.getEmail() == null && request.getPhone() == null) {
            throw new BadRequestException(messages.get("error.auth.emailOrPhoneRequired"));
        }

        User user = createUserByRole(request);
        user.setFullName(request.getFullName());
        user.setEmail(request.getEmail());
        user.setPhone(request.getPhone());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setIsActive(true);

        user = userRepository.save(user);
        user = userRepository.findById(user.getId()).orElseThrow();

        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse loginWithEmail(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new UnauthorizedException(messages.get("error.auth.invalidEmailCredentials")));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new UnauthorizedException(messages.get("error.auth.invalidEmailCredentials"));
        }

        // Audit-4 fix H1 (2026-05-15): an admin-disabled user could still log
        // in (and obtain new tokens) because isActive was set on the entity
        // but never checked during the login flow.
        if (Boolean.FALSE.equals(user.getIsActive())) {
            throw new UnauthorizedException(messages.get("error.auth.accountDisabled"));
        }

        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);

        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse loginWithPhone(PhoneLoginRequest request) {
        User user = userRepository.findByPhone(request.getPhone())
                .orElseThrow(() -> new UnauthorizedException(messages.get("error.auth.invalidPhoneCredentials")));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new UnauthorizedException(messages.get("error.auth.invalidPhoneCredentials"));
        }

        // Audit-4 fix H1 (2026-05-15): same isActive gate as the email path.
        if (Boolean.FALSE.equals(user.getIsActive())) {
            throw new UnauthorizedException(messages.get("error.auth.accountDisabled"));
        }

        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);

        return buildAuthResponse(user);
    }

    public AuthResponse refreshToken(String refreshToken) {
        // Audit-4 fix C5 (2026-05-15): require an actual REFRESH-typed token.
        // Was previously accepting any valid token (including an access token
        // hot off a successful login), so the type distinction was cosmetic.
        if (!jwtService.isRefreshToken(refreshToken)) {
            throw new UnauthorizedException(messages.get("error.auth.invalidRefreshToken"));
        }

        String subject = jwtService.extractSubject(refreshToken);
        User user = userRepository.findByEmail(subject)
                .orElseGet(() -> userRepository.findByPhone(subject)
                        .orElseThrow(() -> new UnauthorizedException("User not found")));

        // Audit-4 fix H1: a disabled account should not be able to mint
        // new tokens via the refresh path either.
        if (Boolean.FALSE.equals(user.getIsActive())) {
            throw new UnauthorizedException(messages.get("error.auth.accountDisabled"));
        }

        return buildAuthResponse(user);
    }

    public User getCurrentUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));
    }

    private User createUserByRole(RegisterRequest request) {
        User user = switch (request.getRole()) {
            case STUDENT -> {
                Student student = new Student();
                student.setGradeLevel(request.getGradeLevel());
                yield student;
            }
            case TEACHER -> new Teacher();
            case PARENT -> new Parent();
            case ADMIN -> new Admin();
            default -> throw new BadRequestException(messages.get("error.auth.invalidRole", request.getRole()));
        };
        user.setRole(request.getRole());
        return user;
    }

    private AuthResponse buildAuthResponse(User user) {
        String accessToken = jwtService.generateAccessToken(user);
        String refreshToken = jwtService.generateRefreshToken(user);

        AuthResponse.AuthResponseBuilder builder = AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .role(user.getRole());

        if (user instanceof Student student) {
            builder.gradeLevel(student.getGradeLevel());
        }

        return builder.build();
    }
}
