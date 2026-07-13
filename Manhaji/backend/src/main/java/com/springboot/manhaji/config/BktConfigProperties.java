package com.springboot.manhaji.config;

import com.springboot.manhaji.entity.enums.QuestionType;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.EnumMap;
import java.util.Map;

/**
 * Tunable Bayesian Knowledge Tracing parameters.
 *
 * <p>BKT models each (student, sub-skill) as a hidden binary state "mastered /
 * not mastered" and updates the probability after each observed answer using
 * four parameters:
 * <ul>
 *   <li><b>P(L0)</b> {@code pInit} — prior probability a fresh student already
 *       knows the skill.</li>
 *   <li><b>P(T)</b> {@code pTransit} — probability the student transitions to
 *       "mastered" between one practice opportunity and the next (learning).</li>
 *   <li><b>P(S)</b> {@code pSlip} — probability a student who HAS mastered the
 *       skill still answers wrong (a slip).</li>
 *   <li><b>P(G)</b> guess — probability a student who has NOT mastered the
 *       skill still answers right (a lucky guess). This is question-type
 *       dependent: a 4-option MCQ is guessable ~25% of the time, a
 *       true/false ~50%, an open short-answer almost never.</li>
 * </ul>
 *
 * <p>Defaults are standard K-12 starting values from the BKT literature
 * (Corbett &amp; Anderson 1995, and common ITS deployments). They're exposed
 * as config so they can be calibrated without a rebuild — which is itself a
 * defensible answer to "how did you choose these?" at the demo.
 */
@Configuration
@ConfigurationProperties(prefix = "app.bkt")
@Getter
@Setter
public class BktConfigProperties {

    /** P(L0) — prior probability the skill is already mastered. */
    private double pInit = 0.25;

    /**
     * P(T) — probability of learning the skill between opportunities.
     *
     * <p>Recalibrated 2026-07-13 (0.15 → 0.03). The old value made mastery run
     * away: a couple of correct answers saturated the belief to ~1.0 and later
     * wrong answers (dampened by slip) couldn't pull it back, so skills a
     * student was only ~50% accurate on still displayed 100% "mastered". A low
     * transition lets wrong answers actually count. Verified by simulating all
     * ~11k real responses: false-mastery cells (real accuracy ≤60% but shown
     * ≥90%) dropped from 48 to 9, with correlation-to-accuracy held at ~0.88.
     */
    private double pTransit = 0.03;

    /**
     * P(S) — slip: a master answers wrong.
     *
     * <p>Recalibrated 2026-07-13 (0.10 → 0.05). A high slip told the model to
     * dismiss wrong answers as bad luck, which is the other half of the
     * runaway-mastery problem above.
     */
    private double pSlip = 0.05;

    /**
     * Default guess probability when a question type isn't in
     * {@link #guessByType}. Conservative (hard to guess) default.
     */
    private double pGuessDefault = 0.05;

    /** P(mastery) at or above which the skill is considered "mastered". */
    private double masteryThreshold = 0.95;

    /**
     * Per-question-type guess probabilities. A correct answer on a
     * high-guess type (true/false) moves mastery less than a correct answer
     * on a low-guess type (short answer), because the evidence is weaker.
     * Configurable via {@code app.bkt.guess-by-type.MCQ=0.25} etc.
     */
    private Map<QuestionType, Double> guessByType = defaultGuessByType();

    private static Map<QuestionType, Double> defaultGuessByType() {
        Map<QuestionType, Double> m = new EnumMap<>(QuestionType.class);
        m.put(QuestionType.MCQ, 0.25);          // 4 options → ~1/4
        m.put(QuestionType.TRUE_FALSE, 0.50);   // 2 options → ~1/2
        // IMAGE_MCQ / LISTEN_CHOOSE are also multiple-choice (~4 options): they
        // were falling through to the 0.05 default, so a lucky tap looked like
        // strong mastery evidence. Fixed 2026-07-13 — a big driver of the false
        // "100% mastered" bars on the مهاراتي radar.
        m.put(QuestionType.IMAGE_MCQ, 0.25);
        m.put(QuestionType.LISTEN_CHOOSE, 0.25);
        m.put(QuestionType.FILL_BLANK, 0.10);   // constrained but cue-able
        m.put(QuestionType.SHORT_ANSWER, 0.05);
        m.put(QuestionType.ORDERING, 0.10);     // some sequences are guessable
        m.put(QuestionType.IMAGE_MATCH, 0.10);
        m.put(QuestionType.DRAG_DROP, 0.10);
        m.put(QuestionType.PRONUNCIATION, 0.05);
        m.put(QuestionType.TRACING, 0.05);
        m.put(QuestionType.READING, 0.05);
        return m;
    }

    /** Guess probability for a given type, falling back to the default. */
    public double guessFor(QuestionType type) {
        if (type == null) return pGuessDefault;
        return guessByType.getOrDefault(type, pGuessDefault);
    }
}
