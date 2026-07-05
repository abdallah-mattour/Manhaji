package com.springboot.manhaji.service;

import com.springboot.manhaji.config.BktConfigProperties;
import com.springboot.manhaji.service.ai.BktEngine;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for the pure Bayesian Knowledge Tracing update.
 *
 * <p>BKT defaults under test (from {@link BktConfigProperties}): P(L0)=0.30,
 * P(T)=0.15, P(S)=0.10, guess varies by question type.
 */
@DisplayName("BktEngine — Bayesian Knowledge Tracing update")
class BktEngineTest {

    private static final double MCQ_GUESS = 0.25;
    private static final double SHORT_ANSWER_GUESS = 0.05;

    private BktEngine engine;

    @BeforeEach
    void setUp() {
        engine = new BktEngine(new BktConfigProperties());
    }

    @Test
    @DisplayName("a correct answer raises mastery")
    void correctRaisesMastery() {
        double prior = 0.30;
        double after = engine.update(prior, true, MCQ_GUESS);
        assertThat(after).isGreaterThan(prior);
    }

    @Test
    @DisplayName("a wrong answer lowers mastery")
    void wrongLowersMastery() {
        double prior = 0.70;
        double after = engine.update(prior, false, MCQ_GUESS);
        assertThat(after).isLessThan(prior);
    }

    @Test
    @DisplayName("a correct MCQ (high guess) raises mastery LESS than a correct short-answer (low guess)")
    void guessWeakensEvidence() {
        double prior = 0.30;
        double afterMcq = engine.update(prior, true, MCQ_GUESS);
        double afterShort = engine.update(prior, true, SHORT_ANSWER_GUESS);
        // A correct answer to a hard-to-guess question is stronger evidence
        // of mastery than a correct answer to an easy-to-guess one.
        assertThat(afterShort).isGreaterThan(afterMcq);
    }

    @Test
    @DisplayName("a streak of correct answers converges above the mastery threshold")
    void streakConverges() {
        double p = 0.30;
        for (int i = 0; i < 8; i++) {
            p = engine.update(p, true, SHORT_ANSWER_GUESS);
        }
        assertThat(p).isGreaterThan(0.95);
        assertThat(engine.isMastered(p)).isTrue();
    }

    @Test
    @DisplayName("mastery stays within [0,1] under repeated updates")
    void staysClamped() {
        double p = 0.30;
        for (int i = 0; i < 20; i++) {
            p = engine.update(p, i % 2 == 0, MCQ_GUESS);
            assertThat(p).isBetween(0.0, 1.0);
        }
    }

    @Test
    @DisplayName("isMastered honors the configured threshold")
    void masteryThreshold() {
        assertThat(engine.isMastered(0.96)).isTrue();
        assertThat(engine.isMastered(0.94)).isFalse();
    }
}
