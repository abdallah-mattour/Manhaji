package com.springboot.manhaji.service.ai;

import com.springboot.manhaji.config.BktConfigProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * Pure Bayesian Knowledge Tracing math. No repositories, no entities — just
 * the probability update, so it's trivially unit-testable in isolation.
 *
 * <p>Given the current belief {@code pL = P(mastered)} and a single observed
 * answer (correct or not), produce the updated belief. Two steps:
 *
 * <ol>
 *   <li><b>Evidence (Bayes):</b> condition pL on the observation using the
 *       slip/guess parameters to get the posterior P(mastered | observation).</li>
 *   <li><b>Learning (transition):</b> the student may have learned the skill
 *       as a result of this opportunity, so nudge the posterior up by P(T).</li>
 * </ol>
 *
 * The classic Corbett &amp; Anderson (1995) update.
 */
@Component
@RequiredArgsConstructor
public class BktEngine {

    private final BktConfigProperties cfg;

    /**
     * Update the mastery belief after one observed answer.
     *
     * @param pL      current P(mastered), in [0,1]
     * @param correct whether the student answered correctly
     * @param guess   P(guess) for this question's type (see {@link BktConfigProperties#guessFor})
     * @return the updated P(mastered), clamped to [0,1]
     */
    public double update(double pL, boolean correct, double guess) {
        double slip = cfg.getPSlip();
        double transit = cfg.getPTransit();

        // Step 1 — Bayesian posterior given the observation.
        double num, den;
        if (correct) {
            // P(mastered AND correct) / P(correct)
            num = pL * (1.0 - slip);
            den = pL * (1.0 - slip) + (1.0 - pL) * guess;
        } else {
            // P(mastered AND wrong) / P(wrong)
            num = pL * slip;
            den = pL * slip + (1.0 - pL) * (1.0 - guess);
        }
        double posterior = (den < 1e-9) ? pL : num / den;

        // Step 2 — learning transition.
        double updated = posterior + (1.0 - posterior) * transit;

        return clamp(updated);
    }

    /** True if the belief is at/above the configured mastery threshold. */
    public boolean isMastered(double pL) {
        return pL >= cfg.getMasteryThreshold();
    }

    private static double clamp(double v) {
        if (v < 0.0) return 0.0;
        if (v > 1.0) return 1.0;
        return v;
    }
}
