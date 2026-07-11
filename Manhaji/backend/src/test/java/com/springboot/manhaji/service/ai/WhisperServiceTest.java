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
 * Unit tests covering Feature B (audit response 2026-04-29):
 * {@link WhisperService#transcribeWithPhonemes} returns a structured
 * {@link PhonemeAnalysis} with graceful fallback for prose / malformed JSON.
 *
 * <p>We exercise {@code parsePhonemeAnalysis} directly so we don't need a live
 * Gemini connection — the HTTP path is covered by the integration sanity check.
 */
class WhisperServiceTest {

    private WhisperService whisperService;

    @BeforeEach
    void setUp() {
        // We don't need a configured Gemini for parser tests, just construct.
        AiConfigProperties config = new AiConfigProperties();
        whisperService = new WhisperService(
                config, WebClient.builder(), new ObjectMapper());
    }

    @Nested
    @DisplayName("parsePhonemeAnalysis()")
    class ParsePhonemeAnalysisTests {

        @Test
        @DisplayName("returns fully populated record on strict JSON")
        void parsesStrictJson() {
            String json = """
                    {
                      "transcribed": "لمان",
                      "phonemeErrors": ["ر"],
                      "guidance": "ركّز على صوت الراء من الحلق"
                    }
                    """;

            PhonemeAnalysis result = whisperService.parsePhonemeAnalysis(json);

            assertThat(result.transcribed()).isEqualTo("لمان");
            assertThat(result.phonemeErrors()).containsExactly("ر");
            assertThat(result.guidance()).isEqualTo("ركّز على صوت الراء من الحلق");
        }

        @Test
        @DisplayName("strips markdown ```json ... ``` fences before parsing")
        void stripsMarkdownFences() {
            String wrapped = "```json\n" + """
                    {"transcribed":"رمان","phonemeErrors":[],"guidance":"ممتاز! نطقك صحيح"}""" + "\n```";

            PhonemeAnalysis result = whisperService.parsePhonemeAnalysis(wrapped);

            assertThat(result.transcribed()).isEqualTo("رمان");
            assertThat(result.phonemeErrors()).isEmpty();
            assertThat(result.guidance()).isEqualTo("ممتاز! نطقك صحيح");
        }

        @Test
        @DisplayName("multiple phoneme errors come through in order")
        void multipleErrorsPreserved() {
            String json = """
                    {"transcribed":"خبر","phonemeErrors":["خ","ر"],"guidance":"كرّر بعدي ببطء"}""";

            PhonemeAnalysis result = whisperService.parsePhonemeAnalysis(json);

            assertThat(result.phonemeErrors()).containsExactly("خ", "ر");
        }

        @Test
        @DisplayName("returns empty record on null/blank input")
        void emptyOnNull() {
            assertThat(whisperService.parsePhonemeAnalysis(null).transcribed()).isEmpty();
            assertThat(whisperService.parsePhonemeAnalysis("   ").phonemeErrors()).isEmpty();
            assertThat(whisperService.parsePhonemeAnalysis("").guidance()).isNull();
        }

        @Test
        @DisplayName("falls back to transcribed-only when Gemini returns prose")
        void fallsBackOnProse() {
            // Common failure mode: Gemini ignores the JSON instruction and writes Arabic.
            String prose = "الطفل يقول رمان بشكل جيد جداً";

            PhonemeAnalysis result = whisperService.parsePhonemeAnalysis(prose);

            assertThat(result.transcribed()).isEqualTo(prose);
            assertThat(result.phonemeErrors()).isEmpty();
            assertThat(result.guidance()).isNull();
        }

        @Test
        @DisplayName("falls back gracefully on malformed JSON")
        void fallsBackOnMalformed() {
            String malformed = "{\"transcribed\": \"رمان\", \"phonemeErrors\": [unclosed";

            PhonemeAnalysis result = whisperService.parsePhonemeAnalysis(malformed);

            // Fallback puts the raw text into transcribed, errors/guidance stay empty.
            assertThat(result.transcribed()).contains("رمان");
            assertThat(result.phonemeErrors()).isEmpty();
            assertThat(result.guidance()).isNull();
        }

        @Test
        @DisplayName("treats blank guidance as null so the UI hides the coaching card")
        void blankGuidanceBecomesNull() {
            String json = """
                    {"transcribed":"رمان","phonemeErrors":[],"guidance":"   "}""";

            PhonemeAnalysis result = whisperService.parsePhonemeAnalysis(json);

            assertThat(result.guidance()).isNull();
        }

        @Test
        @DisplayName("ignores empty string entries inside phonemeErrors array")
        void filtersEmptyPhonemeStrings() {
            String json = """
                    {"transcribed":"رمان","phonemeErrors":["ر","",""],"guidance":"ركّز"}""";

            PhonemeAnalysis result = whisperService.parsePhonemeAnalysis(json);

            assertThat(result.phonemeErrors()).containsExactly("ر");
        }
    }

    @Test
    @DisplayName("transcribeWithPhonemes returns empty record when Gemini not configured")
    void transcribeWithPhonemesFallback() {
        // Default AiConfigProperties has no API key set → isConfigured() == false.
        PhonemeAnalysis result = whisperService.transcribeWithPhonemes(
                new byte[]{1, 2, 3}, "رمان", "ar", "audio/wav");

        assertThat(result).isNotNull();
        assertThat(result.transcribed()).isEmpty();
        assertThat(result.phonemeErrors()).isEmpty();
        assertThat(result.guidance()).isNull();
    }
}
