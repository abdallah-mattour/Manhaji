package com.springboot.manhaji.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateProfileRequest {

    @Size(max = 100, message = "Full name must be 100 characters or fewer")
    private String fullName;

    @Email(message = "Invalid email format")
    private String email;

    @Pattern(regexp = "^\\+?[0-9]{7,15}$",
             message = "Phone must be 7-15 digits, optional leading +")
    private String phone;
}
