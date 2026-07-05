package com.springboot.manhaji.dto.request;

import com.springboot.manhaji.entity.enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Audit-4 fix M1 (2026-05-15): validation tightened.
 * <ul>
 *   <li>password: 6-char minimum (was no constraint).</li>
 *   <li>phone: digit-only pattern with optional + prefix, 7-15 digits.</li>
 *   <li>fullName: max 100 chars to prevent abuse.</li>
 * </ul>
 *
 * <p>Note: gradeLevel-required-for-student is enforced at the service layer
 * because Bean Validation can't easily express "conditionally required based
 * on another field" without a custom validator. AuthService.register checks
 * {@code request.getGradeLevel() != null} when role == STUDENT (TODO).
 */
@Data
public class RegisterRequest {
    @NotBlank(message = "Full name is required")
    @Size(max = 100, message = "Full name must be 100 characters or fewer")
    private String fullName;

    @Email(message = "Invalid email format")
    private String email;

    @Pattern(regexp = "^\\+?[0-9]{7,15}$",
            message = "Phone must be 7-15 digits, optional leading +")
    private String phone;

    @NotBlank(message = "Password is required")
    @Size(min = 6, max = 72, message = "Password must be 6-72 characters")
    private String password;

    @NotNull(message = "Role is required")
    private Role role;

    private Integer gradeLevel;
}
