package com.springboot.manhaji.service.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.springboot.manhaji.config.AiConfigProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.web.reactive.function.client.WebClient;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link TtsService#speechFingerprint} — the cache key that lets
 * the audio cache self-invalidate when a question/lesson's spoken text changes
 * (the content-fingerprinted cache, 2026-06-08).
 *
 * <p>The fingerprint is computed from the <em>sanitized</em> spoken form, so
 * the two properties that matter are: (1) text whose audio would differ gets a
 * different hash, and (2) edits that sanitization collapses away (the
 * FILL_BLANK "___" marker, redundant whitespace) do NOT change the hash, so the
 * cache isn't invalidated for a no-op change.
 */
class TtsServiceTest {

    private TtsService ttsService;

    @BeforeEach
    void setUp() {
        // speechFingerprint is pure (hashes the text); no Gemini/HTTP needed.
        AiConfigProperties config = new AiConfigProperties();
        ttsService = new TtsService(config, WebClient.builder(), new ObjectMapper());
    }

    @Nested
    @DisplayName("speechFingerprint()")
    class SpeechFingerprintTests {

        @Test
        @DisplayName("null / blank text → null (nothing to fingerprint)")
        void nullAndBlankReturnNull() {
            assertThat(ttsService.speechFingerprint(null)).isNull();
            assertThat(ttsService.speechFingerprint("")).isNull();
            assertThat(ttsService.speechFingerprint("   ")).isNull();
            // Underscores sanitize to a lone ellipsis-with-spaces, which trims
            // to "…" — still speakable, so NOT null. (Guards the boundary.)
            assertThat(ttsService.speechFingerprint("___")).isNotNull();
        }

        @Test
        @DisplayName("deterministic — same text → same hash")
        void deterministic() {
            String a = ttsService.speechFingerprint("We read a book at school.");
            String b = ttsService.speechFingerprint("We read a book at school.");
            assertThat(a).isEqualTo(b);
        }

        @Test
        @DisplayName("different spoken text → different hash")
        void differentTextDiffersHash() {
            String book = ttsService.speechFingerprint("We read a book at school.");
            String pen = ttsService.speechFingerprint("We read a pen at school.");
            assertThat(book).isNotEqualTo(pen);
        }

        @Test
        @DisplayName("SHA-256 hex shape — 64 lowercase hex chars")
        void hashShape() {
            String hash = ttsService.speechFingerprint("Hello");
            assertThat(hash).hasSize(64).matches("[0-9a-f]{64}");
        }

        @Test
        @DisplayName("edits sanitization collapses (blank length, whitespace) don't change the hash")
        void noOpEditsKeepHashStable() {
            // The fingerprint hashes the sanitized spoken form, so cosmetic
            // edits that sanitization erases anyway must NOT invalidate the
            // cache (no needless regeneration).
            String base = ttsService.speechFingerprint("Six, ___, eight, nine, ten");
            // Any run of 2+ underscores collapses to the same single pause.
            assertThat(ttsService.speechFingerprint("Six, _____, eight, nine, ten"))
                    .isEqualTo(base);
            // Doubled spaces collapse away too.
            assertThat(ttsService.speechFingerprint("Six,  ___,  eight, nine, ten"))
                    .isEqualTo(base);
        }

        @Test
        @DisplayName("a real word change DOES change the hash (cache will regenerate)")
        void realEditChangesHash() {
            // This is the case that makes the cache self-heal: edit the actual
            // spoken words and the fingerprint diverges, so AudioController sees
            // a stale clip and regenerates it.
            String before = ttsService.speechFingerprint("We read a book at school.");
            String after = ttsService.speechFingerprint("We read a story at school.");
            assertThat(after).isNotEqualTo(before);
        }
    }
}
