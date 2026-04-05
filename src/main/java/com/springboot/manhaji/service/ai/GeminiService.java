package com.springboot.manhaji.service.ai;

import com.springboot.manhaji.config.AiConfigProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class GeminiService {

    private final AiConfigProperties aiConfig;
    private final WebClient.Builder webClientBuilder;

    private static final String GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta";

    public boolean isAvailable() {
        return aiConfig.getGemini().isConfigured();
    }

    /**
     * Evaluate a short answer using Gemini AI.
     * Returns a Map with: isCorrect (boolean), feedback (String), hint (String)
     */
    public Map<String, Object> evaluateShortAnswer(String questionText, String correctAnswer, String studentAnswer, String language) {
        if (!isAvailable()) {
            return null; // Caller should fall back to string matching
        }

        String prompt = buildEvaluationPrompt(questionText, correctAnswer, studentAnswer, language);

        try {
            String response = callGemini(prompt);
            return parseEvaluationResponse(response);
        } catch (Exception e) {
            log.warn("Gemini evaluation failed, falling back to string matching: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Generate a hint for a question at the specified level (1-3).
     */
    public String generateHint(String questionText, String correctAnswer, int hintLevel, String language) {
        if (!isAvailable()) {
            return getDefaultHint(hintLevel, language);
        }

        String prompt = String.format("""
                أنت معلم فلسطيني لطيف للأطفال في الصف الأول.
                السؤال: %s
                الإجابة الصحيحة: %s

                أعطِ تلميحاً من المستوى %d (من 3 مستويات):
                - المستوى 1: تلميح عام وغامض
                - المستوى 2: تلميح أكثر تحديداً
                - المستوى 3: تلميح قريب جداً من الإجابة

                أجب بالتلميح فقط، بجملة واحدة بسيطة مناسبة لطفل.
                """, questionText, correctAnswer, hintLevel);

        try {
            return callGemini(prompt);
        } catch (Exception e) {
            log.warn("Gemini hint generation failed: {}", e.getMessage());
            return getDefaultHint(hintLevel, language);
        }
    }

    /**
     * Generate practice questions for a lesson.
     * Returns raw JSON string from Gemini.
     */
    public String generateQuestions(String lessonContent, String subject, int count, int difficultyLevel) {
        if (!isAvailable()) {
            return null;
        }

        String prompt = String.format("""
                أنت معلم فلسطيني خبير. بناءً على محتوى الدرس التالي، أنشئ %d أسئلة بمستوى صعوبة %d (من 1-3).
                المادة: %s

                محتوى الدرس:
                %s

                أجب بصيغة JSON فقط كمصفوفة من الكائنات:
                [{"type": "MCQ"|"TRUE_FALSE"|"SHORT_ANSWER", "questionText": "...", "correctAnswer": "...", "options": ["..."] أو null, "difficultyLevel": %d}]
                """, count, difficultyLevel, subject, lessonContent, difficultyLevel);

        try {
            return callGemini(prompt);
        } catch (Exception e) {
            log.warn("Gemini question generation failed: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Analyze PDF-extracted text and clean it up.
     */
    public String analyzePdfContent(String rawText, String subject) {
        if (!isAvailable()) {
            return null;
        }

        String prompt = String.format("""
                أنت خبير في المناهج الفلسطينية. النص التالي مستخرج من كتاب %s للصف الأول.
                قد يكون النص العربي مقلوباً أو مشوهاً بسبب استخراجه من PDF.

                المطلوب:
                1. أصلح أي نص عربي مقلوب أو مشوه
                2. نظّم المحتوى بشكل واضح
                3. حدد عنوان الدرس
                4. استخرج الأهداف التعليمية

                النص المستخرج:
                %s

                أجب بصيغة JSON:
                {"title": "عنوان الدرس", "content": "المحتوى المنظم", "objectives": "الأهداف التعليمية"}
                """, subject, rawText);

        try {
            return callGemini(prompt);
        } catch (Exception e) {
            log.warn("Gemini PDF analysis failed: {}", e.getMessage());
            return null;
        }
    }

    // --- Internal methods ---

    private String callGemini(String prompt) {
        String model = aiConfig.getGemini().getModel();
        String apiKey = aiConfig.getGemini().getApiKey();
        String url = String.format("%s/models/%s:generateContent?key=%s", GEMINI_BASE_URL, model, apiKey);

        Map<String, Object> requestBody = Map.of(
                "contents", List.of(
                        Map.of("parts", List.of(
                                Map.of("text", prompt)
                        ))
                ),
                "generationConfig", Map.of(
                        "temperature", 0.3,
                        "maxOutputTokens", 1024
                )
        );

        String responseJson = webClientBuilder.build()
                .post()
                .uri(url)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(String.class)
                .block(java.time.Duration.ofSeconds(30));

        return extractTextFromGeminiResponse(responseJson);
    }

    @SuppressWarnings("unchecked")
    private String extractTextFromGeminiResponse(String json) {
        try {
            var mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            var root = mapper.readTree(json);
            return root.path("candidates").path(0)
                    .path("content").path("parts").path(0)
                    .path("text").asText();
        } catch (Exception e) {
            log.error("Failed to parse Gemini response: {}", e.getMessage());
            throw new RuntimeException("Failed to parse Gemini response", e);
        }
    }

    private Map<String, Object> parseEvaluationResponse(String response) {
        // Try to parse as JSON first
        try {
            var mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            var node = mapper.readTree(response.trim());
            if (node.has("isCorrect")) {
                return Map.of(
                        "isCorrect", node.get("isCorrect").asBoolean(false),
                        "feedback", node.has("feedback") ? node.get("feedback").asText("") : response.trim()
                );
            }
        } catch (Exception ignored) {
            // Not valid JSON, fall back to string matching
        }

        // Fallback: string matching
        String lower = response.toLowerCase();
        boolean isCorrect = lower.contains("\"iscorrect\": true") || lower.contains("\"iscorrect\":true");

        return Map.of(
                "isCorrect", isCorrect,
                "feedback", response.trim()
        );
    }

    private String buildEvaluationPrompt(String questionText, String correctAnswer, String studentAnswer, String language) {
        return String.format("""
                أنت معلم فلسطيني لطيف ومشجع للأطفال في الصف الأول.

                السؤال: %s
                الإجابة الصحيحة: %s
                إجابة الطالب: %s

                قيّم إجابة الطالب. إذا كانت الإجابة صحيحة أو قريبة من الصحيحة، اعتبرها صحيحة.
                كن لطيفاً ومشجعاً في ردك.

                أجب بجملة أو جملتين فقط، مناسبة لطفل في الصف الأول.
                ابدأ بكلمة "صحيحة" إذا كانت الإجابة صحيحة، أو "خاطئة" إذا كانت خاطئة.
                """, questionText, correctAnswer, studentAnswer);
    }

    private String getDefaultHint(int level, String language) {
        return switch (level) {
            case 1 -> "فكّر جيداً في السؤال 🤔";
            case 2 -> "أنت قريب من الإجابة! حاول مرة أخرى 💪";
            case 3 -> "التلميح الأخير: راجع الدرس وستجد الإجابة ⭐";
            default -> "حاول مرة أخرى!";
        };
    }
}
