package com.springboot.manhaji.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * Client-scored tracing submission payload.
 * Tracing evaluation happens client-side (pure CustomPainter heuristic), so the
 * Flutter app sends the final score/stars along with isCorrect. The backend
 * trusts this payload and persists the resulting StudentResponse so dashboards
 * and progress reports reflect the tracing activity.
 */
@Data
public class TracingSubmitRequest {

    @NotNull(message = "Question ID is required")
    private Long questionId;

    @NotNull(message = "Score is required")
    @Min(value = 0, message = "Score must be >= 0")
    @Max(value = 100, message = "Score must be <= 100")
    private Integer score;

    @Min(value = 0, message = "Stars must be >= 0")
    @Max(value = 3, message = "Stars must be <= 3")
    private Integer stars;

    @NotNull(message = "isCorrect is required")
    private Boolean isCorrect;

    private String feedback;
}
