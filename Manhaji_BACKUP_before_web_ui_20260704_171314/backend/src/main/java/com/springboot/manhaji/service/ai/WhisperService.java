package com.springboot.manhaji.service.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.springboot.manhaji.config.AiConfigProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.Base64;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class WhisperService {

    private final AiConfigProperties aiConfig;
    private final WebClient.Builder webClientBuilder;
    private final ObjectMapper objectMapper;  // audit TD3 (2026-04-29)

    private static final String GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta";

    public boolean isAvailable() {
        return aiConfig.getGemini().isConfigured();
    }

    /**
     * Transcribe audio bytes to text using Gemini (free alternative to Whisper).
     *
     * @param audioData the audio file bytes
     * @param language  language code ("ar" for Arabic, "en" for English)
     * @return transcribed text, or an error message if unavailable
     */
    public String transcribe(byte[] audioData, String language) {
        if (!isAvailable()) {
            return "خدمة التعرف على الصوت غير متوفرة حالياً";
        }

        try {
            String base64Audio = Base64.getEncoder().encodeToString(audioData);
            String langName = "ar".equals(language) ? "Arabic" : "English";

            String model = aiConfig.getGemini().getModel();
            String apiKey = aiConfig.getGemini().getApiKey();
            String url = String.format("%s/models/%s:generateContent?key=%s", GEMINI_BASE_URL, model, apiKey);

            Map<String, Object> requestBody = Map.of(
                    "contents", List.of(
                            Map.of("parts", List.of(
                                    Map.of(
                                            "inlineData", Map.of(
                                                    "mimeType", "audio/webm",
                                                    "data", base64Audio
                                            )
                                    ),
                                    Map.of("text", "Transcribe this audio to " + langName + " text. Return ONLY the transcribed text, nothing else.")
                            ))
                    ),
                    "generationConfig", Map.of(
                            "temperature", 0.1,
                            "maxOutputTokens", 512
                    )
            );

            String responseJson = webClientBuilder.build()
                    .post()
                    .uri(url)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block(java.time.Duration.ofSeconds(12));

            return extractTextFromGeminiResponse(responseJson);
        } catch (Exception e) {
            log.error("Audio transcription failed: {}", e.getMessage());
            return "حدث خطأ في التعرف على الصوت. حاول مرة أخرى.";
        }
    }

    /**
     * Transcribe audio AND identify phoneme-level mispronunciations.
     *
     * <p>Feature B (audit, 2026-04-29). Instead of just returning the
     * transcribed string, this overload asks Gemini to produce structured JSON
     * with: what the child actually said, which phonemes/letters they got wrong,
     * and a one-sentence coaching tip in Arabic.
     *
     * <p>Fallbacks (caller is expected to handle either):
     * <ul>
     *   <li>Gemini unavailable → returns {@link PhonemeAnalysis#empty()}.
     *   <li>Gemini returns non-JSON / malformed → returns
     *       {@link PhonemeAnalysis#transcribedOnly} with the raw text so the
     *       legacy scoring path still works.
     * </ul>
     *
     * @param audioData    raw audio bytes (webm/m4a)
     * @param expectedText what the child is supposed to be saying (the target word/ayah)
     * @param language     "ar" or "en"
     */
    public PhonemeAnalysis transcribeWithPhonemes(byte[] audioData, String expectedText, String language) {
        if (!isAvailable()) {
            return PhonemeAnalysis.empty();
        }

        try {
            String base64Audio = Base64.getEncoder().encodeToString(audioData);
            boolean isArabic = "ar".equals(language);
            String langName = isArabic ? "Arabic" : "English";

            String prompt = String.format("""
                    Transcribe this %s audio. The child is attempting to say: "%s"

                    Return JSON ONLY (no prose, no markdown fences). Schema:
                    {
                      "transcribed": "what the child actually said (in %s script)",
                      "phonemeErrors": ["list of individual phonemes/letters the child mispronounced; empty array if none"],
                      "guidance": "ONE short Arabic sentence (max 12 words) coaching the child on the specific phoneme to fix. If pronunciation is essentially correct, return praise like 'ممتاز! نطقك صحيح'."
                    }

                    Important:
                    - The "transcribed" field must reflect what was ACTUALLY heard, not the target.
                    - "phonemeErrors" lists the specific Arabic letters or English phonemes the child needs to practice (e.g. ["ر"], ["ع","خ"]).
                    - "guidance" is always in Arabic regardless of language, since this is a Palestinian Grade 1 app.
                    """, langName, expectedText, langName);

            String model = aiConfig.getGemini().getModel();
            String apiKey = aiConfig.getGemini().getApiKey();
            String url = String.format("%s/models/%s:generateContent?key=%s", GEMINI_BASE_URL, model, apiKey);

            Map<String, Object> requestBody = Map.of(
                    "contents", List.of(
                            Map.of("parts", List.of(
                                    Map.of(
                                            "inlineData", Map.of(
                                                    "mimeType", "audio/webm",
                                                    "data", base64Audio
                                            )
                                    ),
                                    Map.of("text", prompt)
                            ))
                    ),
                    "generationConfig", Map.of(
                            "temperature", 0.2,
                            "maxOutputTokens", 512
                    )
            );

            String responseJson = webClientBuilder.build()
                    .post()
                    .uri(url)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block(java.time.Duration.ofSeconds(12));

            String rawText = extractTextFromGeminiResponse(responseJson);
            return parsePhonemeAnalysis(rawText);
        } catch (Exception e) {
            log.error("Phoneme transcription failed: {}", e.getMessage());
            return PhonemeAnalysis.empty();
        }
    }

    /**
     * Parse Gemini's response into a {@link PhonemeAnalysis}. Handles three shapes:
     * <ol>
     *   <li>Strict JSON matching the requested schema → fully-populated record.
     *   <li>JSON wrapped in markdown code fences (```json ... ```) → strips fences then parses.
     *   <li>Plain prose → falls back to transcribed-only with the prose as the transcription.
     * </ol>
     */
    PhonemeAnalysis parsePhonemeAnalysis(String raw) {
        if (raw == null || raw.isBlank()) {
            return PhonemeAnalysis.empty();
        }
        String trimmed = raw.trim();

        // Strip markdown code fences if present.
        if (trimmed.startsWith("```")) {
            int firstNewline = trimmed.indexOf('\n');
            int lastFence = trimmed.lastIndexOf("```");
            if (firstNewline > 0 && lastFence > firstNewline) {
                trimmed = trimmed.substring(firstNewline + 1, lastFence).trim();
            }
        }

        try {
            var node = objectMapper.readTree(trimmed);
            if (node.isObject() && node.has("transcribed")) {
                String transcribed = node.get("transcribed").asText("");
                List<String> errors = new java.util.ArrayList<>();
                if (node.has("phonemeErrors") && node.get("phonemeErrors").isArray()) {
                    node.get("phonemeErrors").forEach(n -> {
                        String s = n.asText("").trim();
                        if (!s.isEmpty()) errors.add(s);
                    });
                }
                String guidance = node.has("guidance") ? node.get("guidance").asText("").trim() : null;
                if (guidance != null && guidance.isBlank()) guidance = null;
                return new PhonemeAnalysis(transcribed, errors, guidance);
            }
        } catch (Exception ignored) {
            // Fall through to transcribed-only
        }

        // Fallback: Gemini returned plain text instead of JSON.
        return PhonemeAnalysis.transcribedOnly(trimmed);
    }

    private String extractTextFromGeminiResponse(String json) {
        try {
            var root = objectMapper.readTree(json);
            return root.path("candidates").path(0)
                    .path("content").path("parts").path(0)
                    .path("text").asText();
        } catch (Exception e) {
            log.error("Failed to parse transcription response: {}", e.getMessage());
            return "حدث خطأ في معالجة الصوت";
        }
    }
}
