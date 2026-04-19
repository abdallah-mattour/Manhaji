package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.response.AdminStatsResponse;
import com.springboot.manhaji.dto.response.ApiResponse;
import com.springboot.manhaji.dto.response.UserSummaryResponse;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<AdminStatsResponse>> getStats() {
        return ResponseEntity.ok(ApiResponse.success(adminService.getStats()));
    }

    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<UserSummaryResponse>>> getUsers(
            @RequestParam(required = false) Role role) {
        return ResponseEntity.ok(ApiResponse.success(adminService.getAllUsers(role)));
    }
}
