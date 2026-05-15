package com.springboot.manhaji.service;

import com.springboot.manhaji.entity.Question;
import com.springboot.manhaji.entity.StudentResponse;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.repository.QuestionRepository;
import com.springboot.manhaji.repository.StudentResponseRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * Practice-Mode adaptive question selector.
 *
 * <p>Tier A / A1 (2026-05-15): closes the FR-6 / UC-3 gap from the project
 * proposal — "the platform scales difficulty and creates a personalized
 * learning path." The existing {@code getQuizByLesson} returns all questions
 * in fixed order; Practice Mode instead returns N questions sorted by a
 * student-specific weight that prioritises:
 *
 * <ol>
 *   <li><b>Sub-skill weakness</b> (60%) — questions in sub-skills where the
 *       student's past accuracy is low.
 *   <li><b>Difficulty fit</b> (25%) — questions one notch harder than the
 *       student's average correct difficulty.
 *   <li><b>Novelty</b> (15%) — questions the student hasn't seen recently get
 *       a small boost so practice doesn't loop on the same 3 items.
 * </ol>
 *
 * <p>All math is intentionally pure-Java + small-array. No streaming, no DB
 * round-trips inside the loop. A typical Grade-1 lesson has ≤15 questions and
 * ≤30 historical responses per student per lesson — easily fits in memory.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class QuizSelectionService {

    private final QuestionRepository questionRepository;
    private final StudentResponseRepository responseRepository;

    /** Number of questions a Practice-Mode quiz returns by default. */
    public static final int DEFAULT_PRACTICE_SIZE = 10;

    /**
     * Choose {@code count} questions from {@code lessonId} biased toward
     * what {@code studentId} most needs to practise. Order matters — the
     * returned list is the order the student will see questions in.
     *
     * <p>If the student has never seen this lesson before, falls back to
     * returning the first {@code count} questions by ID (same as the legacy
     * fixed-order path) so first-time visitors aren't penalised.
     *
     * @param studentId student looking at Practice Mode
     * @param lessonId  lesson whose questions are eligible
     * @param count     desired result size (clamped to lesson size)
     * @return ordered list of questions, never null, may be empty if the
     *         lesson has no questions
     */
    public List<Question> selectAdaptive(Long studentId, Long lessonId, int count) {
        List<Question> all = questionRepository.findByLessonIdOrderByIdAsc(lessonId);
        if (all.isEmpty()) return List.of();
        int target = Math.max(1, Math.min(count, all.size()));

        List<StudentResponse> history =
                responseRepository.findByStudentIdAndLessonId(studentId, lessonId);

        if (history.isEmpty()) {
            // First-time visitor: fall back to fixed order so the experience
            // doesn't feel "random" before we have any signal.
            return all.subList(0, target);
        }

        // Aggregate accuracy per sub-skill (derived if not set on the question).
        Map<String, int[]> subSkillTallies = new HashMap<>(); // skill -> [correct, total]
        Map<Long, int[]> questionTallies = new HashMap<>();   // qid   -> [correct, total]
        int correctDifficultySum = 0;
        int correctCount = 0;
        for (StudentResponse r : history) {
            Question q = r.getQuestion();
            if (q == null) continue;
            String skill = deriveSubSkill(q);
            int[] sk = subSkillTallies.computeIfAbsent(skill, k -> new int[2]);
            int[] qt = questionTallies.computeIfAbsent(q.getId(), k -> new int[2]);
            sk[1]++;
            qt[1]++;
            if (Boolean.TRUE.equals(r.getIsCorrect())) {
                sk[0]++;
                qt[0]++;
                correctDifficultySum += q.getDifficultyLevel() == null ? 1 : q.getDifficultyLevel();
                correctCount++;
            }
        }
        double avgCorrectDifficulty =
                correctCount == 0 ? 1.0 : (double) correctDifficultySum / correctCount;
        // "Stretch goal" — push the student one notch above what they've mastered.
        double targetDifficulty = Math.min(3.0, avgCorrectDifficulty + 0.5);

        // Score each question.
        record Scored(Question q, double weight) {}
        List<Scored> scored = new ArrayList<>(all.size());
        for (Question q : all) {
            String skill = deriveSubSkill(q);
            int[] sk = subSkillTallies.get(skill);
            double subSkillAccuracy = (sk == null || sk[1] == 0) ? 0.0 : (double) sk[0] / sk[1];

            int diff = q.getDifficultyLevel() == null ? 1 : q.getDifficultyLevel();
            // 1.0 when diff exactly equals target; falls off as it diverges.
            double difficultyFit = 1.0 - Math.min(1.0, Math.abs(diff - targetDifficulty) / 2.0);

            int[] qt = questionTallies.get(q.getId());
            // Novelty: 1.0 if never seen; decays per attempt; min 0.1.
            double novelty = qt == null ? 1.0 : Math.max(0.1, 1.0 - qt[1] * 0.2);

            double weight =
                    0.60 * (1.0 - subSkillAccuracy)
                  + 0.25 * difficultyFit
                  + 0.15 * novelty;

            scored.add(new Scored(q, weight));
        }

        scored.sort((a, b) -> Double.compare(b.weight, a.weight));

        List<Question> out = new ArrayList<>(target);
        for (int i = 0; i < target; i++) {
            out.add(scored.get(i).q);
        }
        log.debug("Adaptive selection for student {} lesson {}: target diff {} chose {} questions",
                studentId, lessonId, String.format("%.2f", targetDifficulty), out.size());
        return out;
    }

    /**
     * Mirror of {@code QuestionAuditTest.deriveSubSkill}: if the question
     * carries an explicit sub-skill tag use it, otherwise derive from type.
     * Kept inline (no shared util) because the audit test reads JSON files
     * and this service reads JPA entities — different inputs.
     */
    private static String deriveSubSkill(Question q) {
        String explicit = q.getSubSkill();
        if (explicit != null && !explicit.isBlank()) return explicit;
        QuestionType t = q.getType();
        if (t == null) return "unknown";
        return switch (t) {
            case MCQ, TRUE_FALSE -> "recognition";
            case SHORT_ANSWER, FILL_BLANK -> "production";
            case ORDERING -> "application";
            case PRONUNCIATION -> "pronunciation";
            case TRACING -> "handwriting";
        };
    }
}
