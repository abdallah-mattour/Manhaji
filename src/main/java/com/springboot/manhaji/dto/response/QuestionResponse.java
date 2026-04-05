package com.springboot.manhaji.dto.response;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class QuestionResponse {
    private Long id;
    private String type;           // TRUE_FALSE, MCQ, SHORT_ANSWER
    private String questionText;
    private List<String> options;  // Parsed from JSON, null for non-MCQ
    private int difficultyLevel;
    // Note: correctAnswer is NOT sent to the client
}
