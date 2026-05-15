package com.springboot.manhaji.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/swagger-ui/**", "/v3/api-docs/**", "/swagger-ui.html").permitAll()
                        // Audit fix S4 (2026-04-29): /uploads/audio/** holds student voice
                        // recordings (PII) — must require auth. /uploads/images/** holds
                        // curriculum images and is safe to serve publicly.
                        .requestMatchers("/uploads/images/**").permitAll()
                        .requestMatchers("/uploads/audio/**").authenticated()
                        // Flutter web bundle (teacher/admin portal) — static assets, unauthenticated.
                        // The Flutter app handles its own auth state via JWT in /api/auth/**.
                        .requestMatchers("/", "/index.html", "/favicon.ico").permitAll()
                        .requestMatchers("/app", "/app/**").permitAll()
                        .requestMatchers("/assets/**", "/icons/**", "/canvaskit/**").permitAll()
                        .requestMatchers("/api/admin/**").hasRole("ADMIN")
                        .requestMatchers("/api/teacher/**").hasAnyRole("TEACHER", "ADMIN")
                        .requestMatchers("/api/parent/**").hasAnyRole("PARENT", "ADMIN")
                        // Audit-4 fix H3 (2026-05-15): previously the rule below
                        // (anyRequest().authenticated()) was the ONLY gate on
                        // /api/student, /api/lessons, /api/quiz, /api/progress,
                        // /api/audio and /api/reports — meaning a teacher token
                        // could hit student-only flows. ADMIN keeps access to
                        // everything for impersonation/inspection in dashboards.
                        .requestMatchers("/api/student/**").hasAnyRole("STUDENT", "ADMIN")
                        .requestMatchers("/api/lessons/**").hasAnyRole("STUDENT", "TEACHER", "ADMIN")
                        .requestMatchers("/api/quiz/**").hasAnyRole("STUDENT", "ADMIN")
                        .requestMatchers("/api/progress/**").hasAnyRole("STUDENT", "PARENT", "TEACHER", "ADMIN")
                        .requestMatchers("/api/audio/**").hasAnyRole("STUDENT", "TEACHER", "ADMIN")
                        .requestMatchers("/api/reports/**").hasAnyRole("STUDENT", "PARENT", "TEACHER", "ADMIN")
                        .requestMatchers("/api/learning-path/**").hasAnyRole("STUDENT", "PARENT", "TEACHER", "ADMIN")
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}
