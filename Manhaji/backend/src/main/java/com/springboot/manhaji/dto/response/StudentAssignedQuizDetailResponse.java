package com.springboot.manhaji.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudentAssignedQuizDetailResponse {
    private Long assignmentId;
    private Long quizId;
    private String title;
    private Long subjectId;
    private String subjectName;
    private Integer questionCount;
    private LocalDateTime dueAt;
    private String status;
    private Long attemptsUsed;
    private Integer maxAttempts;
    private Boolean canStart;
    private List<QuestionResponse> questions;
}
