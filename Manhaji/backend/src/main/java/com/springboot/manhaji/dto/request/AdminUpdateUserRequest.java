package com.springboot.manhaji.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Admin-supplied payload to update a STUDENT or TEACHER. Every field is
 * optional — only provided fields are applied (PATCH semantics).
 *
 * <p>Role is intentionally absent: changing a user's role in-place would
 * require swapping the JPA discriminator row, which Hibernate does not
 * support. To change a user's role, delete and recreate.
 */
@Data
public class AdminUpdateUserRequest {

    @Size(max = 100, message = "Full name must be 100 characters or fewer")
    private String fullName;

    @Email(message = "Invalid email format")
    private String email;

    @Pattern(regexp = "^\\+?[0-9]{7,15}$",
            message = "Phone must be 7-15 digits, optional leading +")
    private String phone;

    @Size(min = 6, max = 72, message = "Password must be 6-72 characters")
    private String password;

    private Boolean isActive;

    // STUDENT-only
    private Integer gradeLevel;

    // TEACHER-only
    private String department;
    private Integer assignedGrade;
}
