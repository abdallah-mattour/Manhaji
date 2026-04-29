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
import com.springboot.manhaji.support.Messages;
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

    @Transactional
    public AuthResponse register(RegisterRequest request) {
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

        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);

        return buildAuthResponse(user);
    }

    public AuthResponse refreshToken(String refreshToken) {
        if (!jwtService.isTokenValid(refreshToken)) {
            throw new UnauthorizedException(messages.get("error.auth.invalidRefreshToken"));
        }

        String subject = jwtService.extractSubject(refreshToken);
        User user = userRepository.findByEmail(subject)
                .orElseGet(() -> userRepository.findByPhone(subject)
                        .orElseThrow(() -> new UnauthorizedException("User not found")));

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
