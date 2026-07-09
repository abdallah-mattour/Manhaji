package com.springboot.manhaji.dto.response;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class QuestionResponse {
    private Long id;
    private String type;           // TRUE_FALSE, MCQ, SHORT_ANSWER, FILL_BLANK, ORDERING, PRONUNCIATION, TRACING
    private String questionText;
    private List<String> options;  // Parsed from JSON, null for non-MCQ
    private int difficultyLevel;
    private String subSkill;       // recognition / production / pronunciation / handwriting / ... — see authoring spec §6
    private String imageUrl;       // Optional — bundled at /static/assets/questions/<path>
    private String audioUrl;       // Optional — same convention
    private List<String> optionImages; // Tier 1 — parallel to options for IMAGE_MCQ / LISTEN_CHOOSE; null otherwise
    private Object pairsJson;          // Tier 1 — IMAGE_MATCH columns+mapping (parsed JSON); null otherwise
    // Note: correctAnswer is NOT sent to the client
}
