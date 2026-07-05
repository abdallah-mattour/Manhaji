package com.springboot.manhaji.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;

/**
 * Per-subject skill-mastery snapshot for the "My Skills" radar chart.
 * One {@link SkillScore} per sub-skill axis the subject teaches.
 */
@Data
@Builder
public class SkillMasteryResponse {

    private final Long subjectId;
    private final String subjectName;
    private final List<SkillScore> skills;

    @Data
    @Builder
    public static class SkillScore {
        /** Sub-skill tag (e.g. "comprehension", "computation"). */
        private final String subSkill;
        /** BKT P(mastered), 0.0-1.0. */
        private final double pMastery;
        /** How many answers have informed this estimate (0 = never practised). */
        private final int observationCount;
        /** True when pMastery ≥ the configured mastery threshold. */
        private final boolean mastered;
    }
}
