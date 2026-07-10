package com.springboot.manhaji.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "app.ai")
@Getter
@Setter
public class AiConfigProperties {

    private Gemini gemini = new Gemini();
    private Whisper whisper = new Whisper();
    private GoogleTts googleTts = new GoogleTts();
    private EdgeTts edgeTts = new EdgeTts();
    private GenerateQuestions generateQuestions = new GenerateQuestions();
    /**
     * Which TTS provider {@link com.springboot.manhaji.service.ai.TtsService}
     * uses. Values: {@code "edge"} (Microsoft Edge neural voices, free, no
     * key — preferred) or {@code "google"} (Google Cloud TTS, requires
     * billing-enabled GOOGLE_TTS_API_KEY).
     */
    private String ttsProvider = "edge";

    @Getter
    @Setter
    public static class Gemini {
        private String apiKey = "not-set";
        private String model = "gemini-2.5-flash";

        public boolean isConfigured() {
            return apiKey != null && !apiKey.isBlank() && !"not-set".equals(apiKey);
        }
    }

    @Getter
    @Setter
    public static class Whisper {
        private String apiKey = "not-set";

        public boolean isConfigured() {
            return apiKey != null && !apiKey.isBlank() && !"not-set".equals(apiKey);
        }
    }

    /**
     * Runtime AI question generation for the personalized "Challenge Me" quiz.
     * When {@code enabled} and {@code GEMINI_API_KEY} is set, Gemini synthesises
     * up to {@code count} extra MCQ/TRUE_FALSE questions targeting the child's
     * weakest sub-skill; they're blended into the bank quiz, keeping the total
     * quiz size. Off by default — flip on for the demo. {@code timeoutSeconds}
     * bounds the live call so a slow Gemini never hangs a quiz load (falls back
     * to a bank-only quiz).
     */
    @Getter
    @Setter
    public static class GenerateQuestions {
        private boolean enabled = false;
        private int count = 3;
        // gemini-2.5-flash generation runs ~4-6s even with thinking disabled, so
        // 10s gives it room while still bounding the fallback well under a hang.
        private int timeoutSeconds = 10;
    }

    @Getter
    @Setter
    public static class GoogleTts {
        private String apiKey = "not-set";

        public boolean isConfigured() {
            return apiKey != null && !apiKey.isBlank() && !"not-set".equals(apiKey);
        }
    }

    /**
     * Microsoft Edge TTS — free neural voices, no API key. Wraps the
     * {@code edge-tts} Python library via a sidecar script. See
     * {@code src/main/resources/tts/edge_tts_sidecar.py} for the runtime
     * and {@code src/main/resources/tts/requirements.txt} for install.
     *
     * <p>Voice naming follows Azure Cognitive Services format
     * ({@code <locale>-<region>-<name>Neural}). Defaults are picked for
     * the Palestinian Grade 1-2 context — Jordanian Arabic for the
     * Levantine accent, warm US English for the "teacher" tone.
     */
    @Getter
    @Setter
    public static class EdgeTts {
        /** Path to the Python interpreter. Use {@code python} if it's on PATH. */
        private String pythonPath = "python";

        /** Voice for ar.* questions. Levantine female (Jordanian) by default. */
        private String voiceArabic = "ar-JO-SanaNeural";

        /** Voice for en.* questions. Microsoft's flagship warm-teacher voice. */
        private String voiceEnglish = "en-US-AriaNeural";

        /** Max wall-clock seconds for a single synthesize call. */
        private int timeoutSeconds = 20;

        /** Edge TTS needs no API key, so this is always "configured". */
        public boolean isConfigured() {
            return true;
        }
    }
}
