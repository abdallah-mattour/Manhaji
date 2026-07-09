package com.springboot.manhaji.dto.request;

import com.springboot.manhaji.entity.enums.Role;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

/**
 * Admin-supplied payload to create a STUDENT or TEACHER directly.
 *
 * <p>Mirrors the validation in {@link RegisterRequest} but allows the admin to
 * also set role-specific fields ({@code gradeLevel}, {@code department},
 * {@code assignedGrade}) that the public self-registration form does not.
 * Role must be STUDENT or TEACHER — admin/parent management is intentionally
 * out of scope for this CRUD surface.
 */
@Data
public class AdminCreateUserRequest {

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

    // STUDENT-only
    private Integer gradeLevel;

    // TEACHER-only
    private String department;
    private Integer assignedGrade;
    @Valid
    private List<TeacherAssignmentRequest> teacherAssignments;
}
