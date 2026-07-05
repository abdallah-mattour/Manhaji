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
public class QuizAttemptSummaryResponse {
    private Long attemptId;
    private String quizTitle;
    private String lessonTitle;
    private String subjectName;
    private Double score;
    private String status;
    private LocalDateTime attemptedAt;
}
