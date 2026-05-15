package com.springboot.manhaji.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class LoginRequest {
    // Audit-4 fix M1 (2026-05-15): added @Email so malformed addresses are
    // rejected at the boundary with a clear 400 instead of falling through
    // to the generic "invalid credentials" path (which is misleading and
    // makes account-recovery harder to debug).
    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 6, message = "Password must be at least 6 characters")
    private String password;
}
