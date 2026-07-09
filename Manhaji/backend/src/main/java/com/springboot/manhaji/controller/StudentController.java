package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.request.UpdateAvatarRequest;
import com.springboot.manhaji.dto.response.ApiResponse;
import com.springboot.manhaji.dto.response.StudentDashboardResponse;
import com.springboot.manhaji.service.StudentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/student")
@RequiredArgsConstructor
public class StudentController {

    private final StudentService studentService;

    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<StudentDashboardResponse>> getDashboard(Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        StudentDashboardResponse dashboard = studentService.getDashboard(studentId);
        return ResponseEntity.ok(ApiResponse.success(dashboard));
    }

    /** Tier 3 (2026-07): set the student's chosen avatar (rewards screen). */
    @PutMapping("/avatar")
    public ResponseEntity<ApiResponse<String>> updateAvatar(Authentication authentication,
                                                            @Valid @RequestBody UpdateAvatarRequest request) {
        Long studentId = (Long) authentication.getPrincipal();
        String saved = studentService.updateAvatar(studentId, request.getAvatarId());
        return ResponseEntity.ok(ApiResponse.success(saved));
    }
}
