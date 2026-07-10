package com.springboot.manhaji.service;

import com.springboot.manhaji.config.BktConfigProperties;
import com.springboot.manhaji.dto.response.SkillMasteryResponse;
import com.springboot.manhaji.dto.response.SkillMasteryResponse.SkillScore;
import com.springboot.manhaji.entity.*;
import com.springboot.manhaji.repository.QuestionRepository;
import com.springboot.manhaji.repository.SkillMasteryRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.StudentResponseRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import com.springboot.manhaji.service.ai.BktEngine;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * Owns the persisted Bayesian Knowledge Tracing state ({@link SkillMastery}).
 *
 * <p>Two responsibilities:
 * <ol>
 *   <li><b>Ingest</b> — {@link #recordResponses} folds a quiz attempt's graded
 *       answers into per-(student, subject, sub-skill) mastery via
 *       {@link BktEngine}. Called from {@code QuizService.completeAttempt}.</li>
 *   <li><b>Read</b> — {@link #getSkillScores} returns the full axis set for a
 *       subject so the Flutter radar chart always has every skill, even ones
 *       the student hasn't practised yet (defaulted to the BKT prior).</li>
 * </ol>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SkillMasteryService {

    private final SkillMasteryRepository skillMasteryRepository;
    private final StudentRepository studentRepository;
    private final SubjectRepository subjectRepository;
    private final QuestionRepository questionRepository;
    private final StudentResponseRepository studentResponseRepository;
    private final BktEngine bktEngine;
    private final BktConfigProperties bktConfig;

    /**
     * Fold an ordered list of graded responses into mastery state. Order
     * matters for BKT (each update builds on the previous belief), so the
     * caller must pass responses in answer order.
     *
     * <p>Each response's subject + sub-skill are derived from its question.
     * Responses whose question or lesson is missing are skipped defensively.
     *
     * @param studentId         the student who answered
     * @param orderedResponses  graded responses, in the order answered
     */
    @Transactional
    public void recordResponses(Long studentId, List<StudentResponse> orderedResponses) {
        if (orderedResponses == null || orderedResponses.isEmpty()) return;

        Student student = studentRepository.findById(studentId).orElse(null);
        if (student == null) {
            log.warn("BKT: student {} not found — skipping mastery update", studentId);
            return;
        }

        // Cache SkillMastery rows by (subjectId, subSkill) within this call so
        // repeated sub-skills in one attempt reuse the in-memory row.
        Map<String, SkillMastery> cache = new HashMap<>();

        for (StudentResponse r : orderedResponses) {
            Question q = r.getQuestion();
            if (q == null || q.getLesson() == null || q.getLesson().getSubject() == null) {
                continue;
            }
            Subject subject = q.getLesson().getSubject();
            String subSkill = QuizSelectionService.deriveSubSkill(q);
            String key = subject.getId() + "|" + subSkill;

            SkillMastery sm = cache.computeIfAbsent(key, k ->
                    loadOrCreate(student, subject, subSkill));

            double guess = bktConfig.guessFor(q.getType());
            double updated = bktEngine.update(
                    sm.getPMastery(), Boolean.TRUE.equals(r.getIsCorrect()), guess);
            sm.setPMastery(updated);
            sm.setObservationCount(sm.getObservationCount() + 1);
        }

        skillMasteryRepository.saveAll(cache.values());
        log.debug("BKT: updated {} skill cells for student {}", cache.size(), studentId);
    }

    /**
     * Re-derive a student's ENTIRE BKT state from their persisted response
     * history, in answer order. Idempotent: wipes the existing mastery cells
     * first, so re-running produces the same result instead of double-counting.
     *
     * <p>Used by {@code DataSeeder} to give demo students real skill mastery
     * (their attempts are written straight to the DB, bypassing
     * {@code completeAttempt} — the normal BKT entry point). Also usable as a
     * one-off "recompute mastery" utility.
     *
     * @return number of responses folded (0 if the student has no history)
     */
    @Transactional
    public int rebuildForStudent(Long studentId) {
        skillMasteryRepository.deleteByStudentId(studentId);
        skillMasteryRepository.flush(); // clear rows before re-insert (unique constraint)

        List<StudentResponse> ordered =
                studentResponseRepository.findAllForBktByStudentId(studentId);
        recordResponses(studentId, ordered);
        return ordered.size();
    }

    private SkillMastery loadOrCreate(Student student, Subject subject, String subSkill) {
        return skillMasteryRepository
                .findByStudentIdAndSubjectIdAndSubSkill(student.getId(), subject.getId(), subSkill)
                .orElseGet(() -> {
                    SkillMastery sm = new SkillMastery();
                    sm.setStudent(student);
                    sm.setSubject(subject);
                    sm.setSubSkill(subSkill);
                    sm.setPMastery(bktConfig.getPInit());
                    sm.setObservationCount(0);
                    return sm;
                });
    }

    /**
     * Build the radar-chart payload for one subject: every sub-skill the
     * subject's questions cover, with the student's mastery (or the BKT prior
     * for skills never practised).
     */
    @Transactional(readOnly = true)
    public SkillMasteryResponse getSkillScores(Long studentId, Long subjectId) {
        Subject subject = subjectRepository.findById(subjectId).orElse(null);
        String subjectName = subject != null ? subject.getName() : "";

        // The full axis set = distinct sub-skills among the subject's questions.
        Set<String> axes = new TreeSet<>();
        for (Question q : questionRepository.findAllBySubjectIdWithLesson(subjectId)) {
            axes.add(QuizSelectionService.deriveSubSkill(q));
        }

        // Persisted mastery for this student+subject.
        Map<String, SkillMastery> persisted = new HashMap<>();
        for (SkillMastery sm : skillMasteryRepository
                .findByStudentIdAndSubjectId(studentId, subjectId)) {
            persisted.put(sm.getSubSkill(), sm);
            axes.add(sm.getSubSkill()); // include any persisted skill not in current question set
        }

        List<SkillScore> skills = new ArrayList<>(axes.size());
        for (String axis : axes) {
            SkillMastery sm = persisted.get(axis);
            double p = sm != null ? sm.getPMastery() : bktConfig.getPInit();
            int obs = sm != null ? sm.getObservationCount() : 0;
            skills.add(SkillScore.builder()
                    .subSkill(axis)
                    .pMastery(p)
                    .observationCount(obs)
                    .mastered(bktEngine.isMastered(p))
                    .build());
        }

        return SkillMasteryResponse.builder()
                .subjectId(subjectId)
                .subjectName(subjectName)
                .skills(skills)
                .build();
    }
}
