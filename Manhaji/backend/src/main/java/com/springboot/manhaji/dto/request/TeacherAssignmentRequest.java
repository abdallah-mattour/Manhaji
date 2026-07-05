package com.springboot.manhaji.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class TeacherAssignmentRequest {

    @NotNull(message = "Subject is required")
    private Long subjectId;

    // Optional client hint; persisted grade is always derived from Subject.gradeLevel.
    private Integer gradeLevel;

    private Long schoolId;
}
