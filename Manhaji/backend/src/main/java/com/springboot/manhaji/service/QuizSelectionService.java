package com.springboot.manhaji.service;

import com.springboot.manhaji.config.BktConfigProperties;
import com.springboot.manhaji.entity.Question;
import com.springboot.manhaji.entity.SkillMastery;
import com.springboot.manhaji.entity.StudentResponse;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.repository.QuestionRepository;
import com.springboot.manhaji.repository.SkillMasteryRepository;
import com.springboot.manhaji.repository.StudentResponseRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
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
    private final SkillMasteryRepository skillMasteryRepository;
    private final BktConfigProperties bktConfig;

    /** Number of questions a Practice-Mode quiz returns by default. */
    public static final int DEFAULT_PRACTICE_SIZE = 10;

    /**
     * RNG for the weighted-random pick in {@link #selectPersonalized} — makes
     * repeated "Challenge Me" taps vary instead of returning an identical quiz.
     * Non-final and package-private-settable so tests can pin the seed.
     */
    private Random random = new Random();

    /** Test hook: pin the RNG so personalized selection is deterministic. */
    void setRandomForTest(Random random) {
        this.random = random;
    }

    /** Weight-ranked candidate, shared by the personalized selection helpers. */
    private record Scored(Question q, double weight) {}

    /**
     * The child's weakest sub-skill in a subject plus the difficulty to aim new
     * practice at — the target for runtime AI question generation. {@code null}
     * on cold start (no BKT observations yet).
     */
    public record WeakSkillTarget(String subSkill, int targetDifficulty) {}

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
     * Select {@code count} questions from across a whole SUBJECT's lessons,
     * weighted toward the sub-skills where the student's BKT mastery is
     * lowest. This is the engine behind the personalized "Challenge Me" quiz.
     *
     * <p>Unlike {@link #selectAdaptive} (which works within one lesson off
     * on-the-fly accuracy), this reads the PERSISTED {@link SkillMastery}
     * BKT model so the selection reflects everything the student has ever
     * done in the subject, not just one lesson's history.
     *
     * <p><b>Cold start</b>: a student with no mastery rows (or all at zero
     * observations) gets the first {@code count} difficulty-1 questions
     * spread round-robin across distinct sub-skills — deterministic (no
     * shuffle, stable for the demo) and seeds the BKT model so the next
     * generation is properly adaptive.
     *
     * @param studentId the student to personalise for
     * @param subjectId the subject to draw questions from
     * @param count     desired number of questions (clamped to availability)
     * @return ordered question list (weakest-skill question first), never null
     */
    public List<Question> selectPersonalized(Long studentId, Long subjectId, int count) {
        List<Question> all = new ArrayList<>(questionRepository.findAllBySubjectIdWithLesson(subjectId));
        // Keep the BKT bank pool purely curriculum: AI-generated questions live
        // in the DB (attached to lessons) but must not re-enter "bank" selection,
        // so the bank/AI blend ratio stays honest.
        all.removeIf(q -> Boolean.TRUE.equals(q.getAiGenerated()));
        if (all.isEmpty()) return List.of();
        int target = Math.max(1, Math.min(count, all.size()));

        List<SkillMastery> masteryRows =
                skillMasteryRepository.findByStudentIdAndSubjectId(studentId, subjectId);
        Map<String, Double> masteryBySkill = new HashMap<>();
        int totalObservations = 0;
        for (SkillMastery sm : masteryRows) {
            masteryBySkill.put(sm.getSubSkill(), sm.getPMastery());
            totalObservations += sm.getObservationCount();
        }

        // Cold start — no signal yet.
        if (totalObservations == 0) {
            return coldStartSelection(all, target);
        }

        // Average mastery sets the difficulty we aim for: weak → easy (1),
        // strong → hard (3).
        double avgMastery = masteryBySkill.values().stream()
                .mapToDouble(Double::doubleValue).average()
                .orElse(bktConfig.getPInit());
        double targetDifficulty = 1.0 + 2.0 * avgMastery; // [1,3]

        // Novelty penalty: questions the student answered in their last
        // ~2×target responses for this subject are "recently seen". Bounded and
        // recency-ordered (one query) so novelty stays meaningful even for a
        // student who has answered most of the subject at some point.
        int recentWindow = Math.max(2 * target, 20);
        Set<Long> recentQids = new HashSet<>(responseRepository.findRecentQuestionIdsBySubject(
                studentId, subjectId, PageRequest.of(0, recentWindow)));

        List<Scored> scored = new ArrayList<>(all.size());
        for (Question q : all) {
            String skill = deriveSubSkill(q);
            double pMastery = masteryBySkill.getOrDefault(skill, bktConfig.getPInit());

            double difficultyFit = 1.0 - Math.min(1.0, Math.abs(difficultyOf(q) - targetDifficulty) / 2.0);
            double novelty = recentQids.contains(q.getId()) ? 0.1 : 1.0;

            double weight =
                    0.60 * (1.0 - pMastery)   // weakest skills first
                  + 0.25 * difficultyFit
                  + 0.15 * novelty;
            scored.add(new Scored(q, weight));
        }

        scored.sort((a, b) -> Double.compare(b.weight(), a.weight()));

        // #1 — weighted-random pick (not strict top-N), so two taps differ.
        // #2 — re-sequence into an easy→hard→achievable arc for a kinder flow.
        List<Question> chosen = weightedSample(scored, target);
        List<Question> out = pedagogicalOrder(chosen);
        log.debug("Personalized selection student {} subject {}: avgMastery {} "
                        + "targetDiff {} chose {} of {} questions",
                studentId, subjectId, String.format("%.2f", avgMastery),
                String.format("%.2f", targetDifficulty), out.size(), all.size());
        return out;
    }

    /**
     * Pick {@code target} questions that both target the child's weak skills AND
     * span several sub-skills, so an adaptive quiz is a varied MIX — never 10
     * questions of one type.
     *
     * <p>Earlier this skimmed the global top-N by weight and capped per skill,
     * but when ONE sub-skill was much weaker than the rest it monopolised the
     * whole top-N (e.g. every ORDERING question outranked everything else), the
     * "distinct skills in the pool" collapsed to 1, and the cap became a no-op —
     * producing a monotone single-type quiz. The fix groups ALL candidates by
     * sub-skill and picks across skills with a HARD per-skill cap, so breadth is
     * structural rather than a side effect of the pool.
     *
     * <ul>
     *   <li>Each pick chooses a sub-skill by weighted randomness (a skill's
     *       weight = its best remaining question), so the weakest skill is
     *       favoured but never monopolises — and repeated taps vary.</li>
     *   <li>A skill is excluded once it hits {@code cap} (≈ target/4, so ~4
     *       skills share a 10-question quiz), forcing the quiz across skills.</li>
     *   <li>Within a skill, the question is a weighted-random draw from its top
     *       few by weight (variety without surfacing its weakest-fit items).</li>
     * </ul>
     */
    private List<Question> weightedSample(List<Scored> rankedByWeightDesc, int target) {
        // Group ALL candidates by sub-skill (each group stays weight-desc).
        LinkedHashMap<String, List<Scored>> bySkill = new LinkedHashMap<>();
        for (Scored s : rankedByWeightDesc) {
            bySkill.computeIfAbsent(deriveSubSkill(s.q()), k -> new ArrayList<>()).add(s);
        }
        int distinctSkills = bySkill.size();
        // Cap one sub-skill (hence question type) to a share of the quiz. Aim to
        // involve up to ~4 skills: target 10 → cap 3; only 2 skills → cap 5.
        int cap = Math.max(2, (int) Math.ceil((double) target / Math.min(Math.max(distinctSkills, 1), 4)));

        // Soft cap on any one question TYPE too, so subjects whose sub-skills
        // are mostly authored as MCQ (English/Math) don't come back all-MCQ even
        // though the sub-skills are diverse. Preference, not a hard limit: if a
        // skill only offers a saturated type we still take it (never get stuck).
        int typeCap = Math.max(3, (int) Math.ceil(target * 0.6));
        Map<String, Integer> takenType = new HashMap<>();

        Map<String, Integer> taken = new HashMap<>();
        List<Question> out = new ArrayList<>(target);
        while (out.size() < target) {
            // Skills still eligible: have questions left and aren't cap-blocked.
            List<String> eligible = new ArrayList<>();
            double totalW = 0.0;
            for (Map.Entry<String, List<Scored>> e : bySkill.entrySet()) {
                if (e.getValue().isEmpty()) continue;
                if (taken.getOrDefault(e.getKey(), 0) >= cap) continue;
                eligible.add(e.getKey());
                totalW += e.getValue().get(0).weight() + 0.01;
            }
            if (eligible.isEmpty()) break;

            // Weighted-random skill (weakest-emphasis + variety), then a
            // type-aware weighted-random question from that skill's top window.
            double dart = random.nextDouble() * totalW;
            double acc = 0.0;
            String skill = eligible.get(eligible.size() - 1);
            for (String s : eligible) {
                acc += bySkill.get(s).get(0).weight() + 0.01;
                if (acc >= dart) { skill = s; break; }
            }
            Scored pick = popWeightedRandom(bySkill.get(skill), takenType, typeCap);
            out.add(pick.q());
            taken.merge(skill, 1, Integer::sum);
            takenType.merge(pick.q().getType().name(), 1, Integer::sum);
        }
        // Top up ignoring the cap if a small skill pool left us short.
        if (out.size() < target) {
            Set<Long> chosen = new HashSet<>();
            for (Question q : out) chosen.add(q.getId());
            for (Scored s : rankedByWeightDesc) {
                if (out.size() == target) break;
                if (chosen.add(s.q().getId())) out.add(s.q());
            }
        }
        return out;
    }

    /**
     * Remove and return one question from a weight-ordered skill group, picked
     * with weighted randomness among its top few — variety without surfacing the
     * skill's weakest-fit questions. Prefers questions whose TYPE hasn't hit
     * {@code typeCap}; falls back to the plain top window if the skill only
     * offers already-saturated types (so selection never stalls).
     */
    private Scored popWeightedRandom(List<Scored> weightOrderedGroup,
                                     Map<String, Integer> takenType, int typeCap) {
        int window = Math.min(weightOrderedGroup.size(), 6);
        List<Integer> idxs = new ArrayList<>();
        for (int i = 0; i < window; i++) {
            String t = weightOrderedGroup.get(i).q().getType().name();
            if (takenType.getOrDefault(t, 0) < typeCap) idxs.add(i);
        }
        if (idxs.isEmpty()) {
            for (int i = 0; i < Math.min(weightOrderedGroup.size(), 4); i++) idxs.add(i);
        }
        double total = 0.0;
        for (int i : idxs) total += weightOrderedGroup.get(i).weight() + 0.01;
        double dart = random.nextDouble() * total;
        double acc = 0.0;
        int chosen = idxs.get(idxs.size() - 1);
        for (int i : idxs) {
            acc += weightOrderedGroup.get(i).weight() + 0.01;
            if (acc >= dart) { chosen = i; break; }
        }
        return weightOrderedGroup.remove(chosen);
    }

    /**
     * Re-sequence a chosen set into a kid-friendly difficulty arc (#2): open on
     * the easiest question (an early win), ramp up through the hardest in the
     * middle, and finish on an achievable one rather than the peak. Selection
     * stays adaptive — this only reorders what was already chosen. Public so
     * {@code QuizService} can re-apply it after blending AI questions in.
     */
    public List<Question> pedagogicalOrder(List<Question> chosen) {
        if (chosen.size() <= 2) return chosen; // too small for a meaningful arc
        List<Question> sorted = new ArrayList<>(chosen);
        sorted.sort(Comparator.comparingInt(QuizSelectionService::difficultyOf));
        Question opener = sorted.get(0);              // easiest → warm-up win
        Question closer = sorted.get(1);              // 2nd-easiest → gentle finish
        List<Question> out = new ArrayList<>(chosen.size());
        out.add(opener);
        out.addAll(sorted.subList(2, sorted.size())); // ascending → ramps to the peak
        out.add(closer);
        return out;
    }

    private static int difficultyOf(Question q) {
        return q.getDifficultyLevel() == null ? 1 : q.getDifficultyLevel();
    }

    /**
     * The child's weakest sub-skill in a subject and the difficulty to aim new
     * questions at — used by the runtime AI generator to target exactly where
     * the student is struggling. "Weakest" = the persisted BKT cell with the
     * lowest {@code pMastery}; the difficulty mirrors {@code selectPersonalized}'s
     * {@code 1 + 2·avgMastery} (clamped to 1..3). Returns {@code null} on cold
     * start (no observations) so the caller can skip generation and serve the
     * curriculum bank instead.
     */
    public WeakSkillTarget analyzeWeakestSkill(Long studentId, Long subjectId) {
        List<SkillMastery> rows =
                skillMasteryRepository.findByStudentIdAndSubjectId(studentId, subjectId);
        int totalObservations = 0;
        double masterySum = 0.0;
        SkillMastery weakest = null;
        for (SkillMastery sm : rows) {
            totalObservations += sm.getObservationCount();
            masterySum += sm.getPMastery();
            if (weakest == null || sm.getPMastery() < weakest.getPMastery()) {
                weakest = sm;
            }
        }
        if (totalObservations == 0 || weakest == null) {
            return null; // cold start — no signal to target yet
        }
        double avgMastery = masterySum / rows.size();
        int targetDifficulty = (int) Math.round(1.0 + 2.0 * avgMastery);
        targetDifficulty = Math.max(1, Math.min(3, targetDifficulty));
        return new WeakSkillTarget(weakest.getSubSkill(), targetDifficulty);
    }

    /**
     * Cold-start fallback: easiest questions, one per distinct sub-skill in
     * round-robin so the first quiz touches the breadth of the subject and
     * seeds a mastery signal for every axis.
     */
    private List<Question> coldStartSelection(List<Question> all, int target) {
        // Bucket difficulty-1 questions by sub-skill, preserving encounter order.
        LinkedHashMap<String, Deque<Question>> bySkill = new LinkedHashMap<>();
        for (Question q : all) {
            int diff = q.getDifficultyLevel() == null ? 1 : q.getDifficultyLevel();
            if (diff != 1) continue;
            bySkill.computeIfAbsent(deriveSubSkill(q), k -> new ArrayDeque<>()).add(q);
        }
        // If there are no difficulty-1 questions at all, just take the first N.
        if (bySkill.isEmpty()) return all.subList(0, target);

        List<Question> out = new ArrayList<>(target);
        while (out.size() < target) {
            boolean progressed = false;
            for (Deque<Question> bucket : bySkill.values()) {
                if (!bucket.isEmpty()) {
                    out.add(bucket.poll());
                    progressed = true;
                    if (out.size() == target) break;
                }
            }
            if (!progressed) break; // exhausted all difficulty-1 questions
        }
        // Top up with any remaining questions if we ran short on difficulty-1.
        if (out.size() < target) {
            for (Question q : all) {
                if (!out.contains(q)) {
                    out.add(q);
                    if (out.size() == target) break;
                }
            }
        }
        return out;
    }

    /**
     * Mirror of {@code QuestionAuditTest.deriveSubSkill}: if the question
     * carries an explicit sub-skill tag use it, otherwise derive from type.
     * Kept inline (no shared util) because the audit test reads JSON files
     * and this service reads JPA entities — different inputs.
     *
     * <p>Public + static so {@code SkillMasteryService} can reuse the exact
     * same derivation (single source of truth for entity-based sub-skill
     * resolution).
     */
    public static String deriveSubSkill(Question q) {
        String explicit = q.getSubSkill();
        if (explicit != null && !explicit.isBlank()) return explicit;
        QuestionType t = q.getType();
        if (t == null) return "unknown";
        return switch (t) {
            case MCQ, TRUE_FALSE, IMAGE_MCQ, LISTEN_CHOOSE -> "recognition";
            case SHORT_ANSWER, FILL_BLANK -> "production";
            case ORDERING, IMAGE_MATCH, DRAG_DROP -> "application";
            case PRONUNCIATION -> "pronunciation";
            case TRACING -> "handwriting";
            case READING -> "reading";
        };
    }
}
