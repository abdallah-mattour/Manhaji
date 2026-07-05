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
    private double pInit = 0.30;

    /** P(T) — probability of learning the skill between opportunities. */
    private double pTransit = 0.15;

    /** P(S) — slip: a master answers wrong. */
    private double pSlip = 0.10;

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
        m.put(QuestionType.FILL_BLANK, 0.10);   // constrained but cue-able
        m.put(QuestionType.SHORT_ANSWER, 0.05);
        m.put(QuestionType.ORDERING, 0.05);
        m.put(QuestionType.PRONUNCIATION, 0.05);
        m.put(QuestionType.TRACING, 0.05);
        return m;
    }

    /** Guess probability for a given type, falling back to the default. */
    public double guessFor(QuestionType type) {
        if (type == null) return pGuessDefault;
        return guessByType.getOrDefault(type, pGuessDefault);
    }
}
