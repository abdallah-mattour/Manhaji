package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.response.AuthResponse;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.exception.AuthenticationFailedException;
import com.springboot.manhaji.exception.GlobalExceptionHandler;
import com.springboot.manhaji.service.AuthService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    @Mock
    private AuthService authService;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders
                .standaloneSetup(new AuthController(authService))
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("invalid login credentials return 401")
    void invalidLoginCredentialsReturnUnauthorized() throws Exception {
        when(authService.loginWithEmail(any()))
                .thenThrow(new AuthenticationFailedException("Invalid email or password"));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "missing@example.com",
                                  "password": "badpass"
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Invalid email or password"));
    }

    @Test
    @DisplayName("me response includes avatarId from profile DTO")
    void meResponseIncludesAvatarId() throws Exception {
        when(authService.getCurrentProfile(42L)).thenReturn(AuthResponse.builder()
                .userId(42L)
                .fullName("معلم")
                .email("teacher@example.com")
                .role(Role.TEACHER)
                .avatarId("avatar-star")
                .build());

        mockMvc.perform(get("/api/auth/me")
                        .principal(new TestingAuthenticationToken(42L, null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.userId").value(42))
                .andExpect(jsonPath("$.data.avatarId").value("avatar-star"));
    }
}
