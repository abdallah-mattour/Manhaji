package com.springboot.manhaji.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TeacherAssignmentAttemptResponse {
    private Long attemptId;
    private Long studentId;
    private String studentName;
    private String status;
    private Double score;
    private LocalDateTime startedAt;
    private LocalDateTime submittedAt;
}
