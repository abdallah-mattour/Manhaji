package com.springboot.manhaji.service.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.springboot.manhaji.config.AiConfigProperties;
import com.springboot.manhaji.entity.Lesson;
import com.springboot.manhaji.entity.Question;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.repository.QuestionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Runtime AI question generation for the personalized "Challenge Me" quiz.
 *
 * <p>Given a lesson, the child's weakest sub-skill and a target difficulty, asks
 * Gemini (via {@link GeminiService#generateJson}) for a small batch of brand-new
 * MCQ / TRUE_FALSE questions grounded in that lesson, validates each one hard,
 * drops anything invalid, and persists the survivors (real IDs → scoreable
 * through the normal {@code QuizService.submitAnswer} path). Persisted rows are
 * marked {@code aiGenerated=true} so {@code QuizSelectionService} keeps them out
 * of the curriculum bank pool.
 *
 * <p><b>Never throws.</b> Any failure — model unavailable, timeout, malformed
 * JSON, all items invalid — returns an empty list so the caller falls back to a
 * bank-only quiz and the child never sees an error or a hang.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AiQuestionGenerationService {

    private final GeminiService geminiService;
    private final QuestionRepository questionRepository;
    private final ObjectMapper objectMapper;
    private final AiConfigProperties aiConfig;

    /** Only these two types are safe to generate + auto-score without assets. */
    private static final Set<QuestionType> ALLOWED_TYPES =
            Set.of(QuestionType.MCQ, QuestionType.TRUE_FALSE);

    /**
     * Generate + persist up to {@code count} validated questions for
     * {@code lesson}, targeting {@code subSkill} at {@code targetDifficulty}.
     *
     * @param language "en" for English subjects, anything else → Arabic.
     * @return persisted, validated questions (may be empty; never null).
     */
    public List<Question> generate(Lesson lesson, String subSkill, int targetDifficulty,
                                   int count, String language) {
        if (lesson == null || count <= 0 || !geminiService.isAvailable()) {
            return List.of();
        }
        try {
            String prompt = buildPrompt(lesson, subSkill, targetDifficulty, count, language);
            int timeout = aiConfig.getGenerateQuestions().getTimeoutSeconds();
            String raw = geminiService.generateJson(prompt, timeout);
            JsonNode arr = objectMapper.readTree(GeminiService.stripJsonFences(raw));
            if (arr == null || !arr.isArray()) {
                log.warn("AI question gen: expected a JSON array, got {}",
                        arr == null ? "null" : arr.getNodeType());
                return List.of();
            }

            boolean arabic = !"en".equalsIgnoreCase(language);
            Set<String> seen = existingQuestionTexts(lesson);
            List<Question> out = new ArrayList<>();
            for (JsonNode item : arr) {
                if (out.size() >= count) break;
                Question q = validateAndBuild(item, lesson, subSkill, arabic, seen);
                if (q != null) {
                    out.add(questionRepository.save(q));
                    seen.add(norm(q.getQuestionText()));
                }
            }
            log.info("AI question gen: lesson '{}' subSkill '{}' diff {} → {} of {} valid",
                    lesson.getTitle(), subSkill, targetDifficulty, out.size(), count);
            return out;
        } catch (Exception e) {
            log.warn("AI question gen failed (non-fatal, bank fallback): {}", e.getMessage());
            return List.of();
        }
    }

    // ── Prompt ──────────────────────────────────────────────────────────────

    private String buildPrompt(Lesson lesson, String subSkill, int targetDifficulty,
                               int count, String language) {
        String langLine = "en".equalsIgnoreCase(language)
                ? "Write every question in simple ENGLISH suitable for a 6-year-old."
                : "اكتب كل الأسئلة باللغة العربية الفصحى المبسّطة جداً.";
        return String.format("""
                أنت معلّم فلسطيني خبير في الصف الأول الابتدائي، تصمّم أسئلة تدريبية لطفل عمره 6 سنوات.
                الجمهور: أطفال الصف الأول في فلسطين — استخدم لغة بسيطة جداً وآمنة ومناسبة ثقافياً.

                الدرس: %s
                محتوى الدرس: %s
                الأهداف: %s

                المهارة المستهدفة: %s
                مستوى الصعوبة المطلوب: %d (1 سهل، 2 متوسط، 3 صعب)

                اكتب %d أسئلة جديدة **حول محتوى هذا الدرس حصراً**. %s

                قواعد صارمة يجب الالتزام بها:
                - النوع MCQ أو TRUE_FALSE فقط (لا شيء غير ذلك).
                - لكل سؤال إجابة واحدة صحيحة لا لبس فيها.
                - MCQ: من 3 إلى 4 خيارات، والإجابة الصحيحة يجب أن تطابق أحد الخيارات تماماً.
                - TRUE_FALSE: قيمة correctAnswer إما "صح" أو "خطأ" فقط، وoptions = null.
                - ممنوع أي محتوى عنيف أو مخيف أو غير مناسب أو خارج عن الدرس.

                أعِد مصفوفة JSON فقط، دون أي نص قبلها أو بعدها. كل عنصر بهذا الشكل بالضبط:
                {"type":"MCQ|TRUE_FALSE","questionText":"...","correctAnswer":"...","options":["...","..."] أو null,"difficultyLevel":%d}
                """,
                nz(lesson.getTitle()),
                truncate(lesson.getContent(), 800),
                truncate(lesson.getObjectives(), 400),
                nz(subSkill), targetDifficulty, count, langLine, targetDifficulty);
    }

    // ── Validation ──────────────────────────────────────────────────────────

    private Question validateAndBuild(JsonNode item, Lesson lesson, String subSkill,
                                      boolean arabic, Set<String> seen) {
        if (item == null || !item.isObject()) return null;

        QuestionType type = parseType(text(item, "type"));
        if (type == null || !ALLOWED_TYPES.contains(type)) return null;

        String questionText = text(item, "questionText");
        String correctAnswer = text(item, "correctAnswer");
        if (isBlank(questionText) || isBlank(correctAnswer)) return null;
        questionText = questionText.trim();
        correctAnswer = correctAnswer.trim();

        int difficulty = item.path("difficultyLevel").asInt(0);
        if (difficulty < 1 || difficulty > 3) return null;

        // Reject English-only leakage in an Arabic subject.
        if (arabic && !containsArabic(questionText)) return null;

        // Drop duplicates of an existing (or already-accepted) question.
        if (seen.contains(norm(questionText))) return null;

        String optionsJson = null;
        if (type == QuestionType.MCQ) {
            List<String> options = readOptions(item.get("options"));
            if (options.size() < 3 || options.size() > 4) return null;
            String ca = correctAnswer;
            boolean correctInOptions =
                    options.stream().anyMatch(o -> o.equalsIgnoreCase(ca));
            if (!correctInOptions) return null;
            try {
                optionsJson = objectMapper.writeValueAsString(options);
            } catch (Exception e) {
                return null;
            }
        } else { // TRUE_FALSE — correctAnswer must be صح/خطأ; options stay null.
            String canonical = canonicalTrueFalse(correctAnswer);
            if (canonical == null) return null;
            correctAnswer = canonical;
        }

        Question q = new Question();
        q.setType(type);
        q.setQuestionText(questionText);
        q.setCorrectAnswer(correctAnswer);
        q.setOptions(optionsJson);
        q.setDifficultyLevel(difficulty);
        q.setSubSkill(subSkill);
        q.setLesson(lesson);
        q.setAiGenerated(true);
        return q;
    }

    private Set<String> existingQuestionTexts(Lesson lesson) {
        Set<String> set = new HashSet<>();
        for (Question q : questionRepository.findByLessonId(lesson.getId())) {
            if (q.getQuestionText() != null) set.add(norm(q.getQuestionText()));
        }
        return set;
    }

    // ── Small helpers ───────────────────────────────────────────────────────

    private static QuestionType parseType(String s) {
        if (s == null) return null;
        try {
            return QuestionType.valueOf(s.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private List<String> readOptions(JsonNode node) {
        List<String> out = new ArrayList<>();
        if (node != null && node.isArray()) {
            for (JsonNode o : node) {
                if (o != null && !o.isNull()) {
                    String s = o.asText(null);
                    if (s != null && !s.isBlank()) out.add(s.trim());
                }
            }
        }
        return out;
    }

    /** Mirrors {@code QuizService.canonicalTrueFalse} — maps to صح/خطأ or null. */
    private static String canonicalTrueFalse(String s) {
        if (s == null) return null;
        return switch (s.trim().toLowerCase()) {
            case "صح", "صحيح", "true", "نعم" -> "صح";
            case "خطأ", "خطا", "false", "لا" -> "خطأ";
            default -> null;
        };
    }

    private static boolean containsArabic(String s) {
        if (s == null) return false;
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c >= 0x0600 && c <= 0x06FF) return true;
        }
        return false;
    }

    private static String text(JsonNode node, String field) {
        JsonNode v = node.get(field);
        return (v == null || v.isNull()) ? null : v.asText();
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }

    private static String norm(String s) {
        return s == null ? "" : s.trim().toLowerCase();
    }

    private static String nz(String s) {
        return s == null ? "" : s;
    }

    private static String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max);
    }
}
