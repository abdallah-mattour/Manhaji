package com.springboot.manhaji.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TeacherQuizAssignmentRequest {
    @NotNull
    private Integer gradeLevel;

    private Long schoolId;

    private LocalDateTime dueAt;

    @Positive
    private Integer maxAttempts;

    private List<Long> studentIds;
}
