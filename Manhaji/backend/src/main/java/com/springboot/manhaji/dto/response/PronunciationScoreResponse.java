package com.springboot.manhaji.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class PronunciationScoreResponse {
    private Long questionId;
    private String expectedText;
    private String transcribedText;
    private int score;
    private String rating;
    private String feedback;
    private boolean isCorrect;
    private int pointsEarned;

    /**
     * Feature B (2026-04-29): phonemes the child mispronounced, e.g. ["ر","ع"].
     * Empty when AI not available or pronunciation is essentially correct.
     */
    private List<String> phonemeErrors;

    /**
     * Feature B (2026-04-29): a single Arabic coaching sentence from Gemini,
     * e.g. "ركّز على صوت الراء من الحلق". Null when AI not available.
     */
    private String guidance;
}
