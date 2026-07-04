package com.springboot.manhaji.entity.enums;

public enum QuestionType {
    TRUE_FALSE,
    MCQ,
    SHORT_ANSWER,
    FILL_BLANK,
    ORDERING,
    PRONUNCIATION,
    TRACING,
    // Tier 1 (2026-06) interactive types.
    // IMAGE_MCQ + LISTEN_CHOOSE reuse MCQ scoring (correctAnswer ∈ options);
    // IMAGE_MATCH scores by comparing the submitted left=right pair mapping.
    IMAGE_MCQ,
    LISTEN_CHOOSE,
    IMAGE_MATCH,
    // Tier 2 (2026-07): student drags word tokens into named target groups.
    // Data lives in pairsJson as {targets:[...], tokens:[...]}; the submitted
    // answer is "target=token,..." so scoring reuses IMAGE_MATCH's pair-set
    // comparison unchanged.
    DRAG_DROP,
    // Tier 4 (2026-07): read-aloud passage. questionText == correctAnswer ==
    // the passage (same convention as PRONUNCIATION). Scored word-by-word via
    // ReadingComparisonService inside the existing pronunciation endpoint.
    READING
}
