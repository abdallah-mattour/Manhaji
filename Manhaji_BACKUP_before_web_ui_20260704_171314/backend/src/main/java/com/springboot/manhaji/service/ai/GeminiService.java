package com.springboot.manhaji.service.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
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
    private final ObjectMapper objectMapper;  // audit TD3 (2026-04-29): Spring's auto-configured singleton

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
     * Generate a progress report summary for a student based on their performance data.
     */
    public String generateProgressReport(String studentName, int gradeLevel,
                                          String performanceData) {
        if (!isAvailable()) {
            return null;
        }

        String prompt = String.format("""
                أنت مستشار تربوي فلسطيني متخصص في التعليم الابتدائي.
                اكتب تقريراً مختصراً وواضحاً عن تقدم الطالب التالي:

                اسم الطالب: %s
                الصف: %d

                بيانات الأداء (أرقام حقيقية):
                %s

                المطلوب:
                1. ملخص عام عن أداء الطالب (2-3 جمل) — يجب أن يذكر أرقاماً محددة من
                   البيانات أعلاه (عدد الدروس المكتملة، متوسط الإتقان، أو الدرجات)
                   بدلاً من عبارات عامة.
                2. نقاط القوة (2-3 نقاط) — مبنية على المواد ذات الإتقان الأعلى.
                3. نقاط تحتاج تحسين (2-3 نقاط) — مبنية على المواد الأضعف تحديداً.
                4. توصيات عملية لولي الأمر (2-3 نقاط).
                5. مستوى الخطر: LOW (إتقان جيد) أو MEDIUM أو HIGH (يحتاج دعماً عاجلاً).

                إذا لم تكن هناك بيانات كافية، اذكر ذلك بوضوح واطلب من الطالب إكمال
                بعض الدروس أولاً.

                أجب بصيغة JSON فقط، دون أي نص قبله أو بعده:
                {"summary": "...", "strengths": ["..."], "improvements": ["..."], "recommendations": ["..."], "riskLevel": "LOW|MEDIUM|HIGH"}
                """, studentName, gradeLevel, performanceData);

        try {
            return callGemini(prompt);
        } catch (Exception e) {
            log.warn("Gemini progress report generation failed: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Generate personalized learning path recommendations for a student.
     */
    public String generateLearningPath(String studentName, int gradeLevel,
                                        String weakAreas, String completedLessons) {
        if (!isAvailable()) {
            return null;
        }

        String prompt = String.format("""
                أنت معلم ذكي يصمم خطط تعلّم مخصصة لطلاب الصف الأول في فلسطين.

                الطالب: %s (الصف %d)

                المواضيع الضعيفة:
                %s

                الدروس المكتملة:
                %s

                صمّم خطة تعلّم مخصصة تتضمن:
                1. ترتيب الدروس المقترحة للمراجعة (الأضعف أولاً)
                2. أنشطة إضافية مقترحة
                3. نصائح للطالب

                أجب بصيغة JSON فقط:
                {"reviewLessons": [{"subject": "...", "topic": "...", "reason": "..."}], "activities": ["..."], "tips": ["..."]}
                """, studentName, gradeLevel, weakAreas, completedLessons);

        try {
            return callGemini(prompt);
        } catch (Exception e) {
            log.warn("Gemini learning path generation failed: {}", e.getMessage());
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
                .block(java.time.Duration.ofSeconds(12));

        return extractTextFromGeminiResponse(responseJson);
    }

    @SuppressWarnings("unchecked")
    private String extractTextFromGeminiResponse(String json) {
        try {
            var root = objectMapper.readTree(json);
            return root.path("candidates").path(0)
                    .path("content").path("parts").path(0)
                    .path("text").asText();
        } catch (Exception e) {
            log.error("Failed to parse Gemini response: {}", e.getMessage());
            throw new RuntimeException("Failed to parse Gemini response", e);
        }
    }

    /**
     * Strips Markdown code-fences (```json ... ``` or ``` ... ```) that Gemini
     * frequently wraps around JSON despite being asked for JSON-only. Returns
     * the inner content, trimmed. Safe on already-clean input (returns it
     * unchanged). Public so report/learning-path services can clean the raw
     * response before {@code objectMapper.readTree(...)} — without this, the
     * fenced blob fails to parse and the raw ```json...``` string leaks into
     * the UI (see ProgressReportService).
     */
    public static String stripJsonFences(String response) {
        if (response == null) return "";
        String trimmed = response.trim();
        if (trimmed.startsWith("```")) {
            int firstNewline = trimmed.indexOf('\n');
            int lastFence = trimmed.lastIndexOf("```");
            if (firstNewline > 0 && lastFence > firstNewline) {
                trimmed = trimmed.substring(firstNewline + 1, lastFence).trim();
            }
        }
        return trimmed;
    }

    private Map<String, Object> parseEvaluationResponse(String response) {
        String trimmed = stripJsonFences(response);

        // Try strict JSON first (the prompt requests JSON-only).
        try {
            var node = objectMapper.readTree(trimmed);
            if (node.has("isCorrect")) {
                return Map.of(
                        "isCorrect", node.get("isCorrect").asBoolean(false),
                        "feedback", node.has("feedback") ? node.get("feedback").asText("") : trimmed
                );
            }
        } catch (Exception ignored) {
            // Fall through to heuristic
        }

        // Heuristic fallback for narrative responses (audit fix 2026-04-29):
        // The previous fallback looked for the literal substring "iscorrect: true",
        // which a narrative response will essentially never contain. Instead match
        // on Arabic/English correctness vocabulary the prompt instructs Gemini to use.
        String lower = trimmed.toLowerCase();
        boolean isCorrect = trimmed.startsWith("صحيحة")
                         || trimmed.startsWith("صحيح")
                         || trimmed.startsWith("صحّ")
                         || lower.startsWith("correct")
                         || lower.contains("\"iscorrect\":true")
                         || lower.contains("\"iscorrect\": true");

        return Map.of(
                "isCorrect", isCorrect,
                "feedback", trimmed
        );
    }

    private String buildEvaluationPrompt(String questionText, String correctAnswer, String studentAnswer, String language) {
        return String.format("""
                أنت معلم فلسطيني لطيف ومشجع للأطفال في الصف الأول.

                السؤال: %s
                الإجابة الصحيحة: %s
                إجابة الطالب: %s

                قيّم إجابة الطالب. إذا كانت الإجابة صحيحة أو قريبة من الصحيحة، اعتبرها صحيحة.
                كن لطيفاً ومشجعاً في ردك. اجعل التغذية الراجعة جملة أو جملتين فقط، مناسبة لطفل في الصف الأول.

                IMPORTANT: Respond with JSON only. Do NOT add any prose before or after.
                Format:
                {"isCorrect": true|false, "feedback": "<one or two short sentences in Arabic>"}
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
