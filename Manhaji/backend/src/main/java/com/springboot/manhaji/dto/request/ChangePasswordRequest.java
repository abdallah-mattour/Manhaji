package com.springboot.manhaji.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Change-password payload (2026-07-07). Mirrors {@link RegisterRequest}'s
 * password constraints so the new password is subject to the same 6-72 char
 * rule. The current password is only checked for presence here; correctness is
 * verified against the stored hash in {@code AuthService.changePassword}.
 */
@Data
public class ChangePasswordRequest {
    @NotBlank(message = "Current password is required")
    private String currentPassword;

    @NotBlank(message = "New password is required")
    @Size(min = 6, max = 72, message = "Password must be 6-72 characters")
    private String newPassword;
}
