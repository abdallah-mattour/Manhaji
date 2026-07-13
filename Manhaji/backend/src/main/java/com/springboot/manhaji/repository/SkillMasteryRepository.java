package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.SkillMastery;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SkillMasteryRepository extends JpaRepository<SkillMastery, Long> {

    /** All persisted sub-skill mastery rows for a student in one subject. */
    List<SkillMastery> findByStudentIdAndSubjectId(Long studentId, Long subjectId);

    /** Every persisted sub-skill mastery row for a student across all subjects. */
    List<SkillMastery> findByStudentId(Long studentId);

    /** The one row for a specific (student, subject, sub-skill) cell, if it exists. */
    Optional<SkillMastery> findByStudentIdAndSubjectIdAndSubSkill(
            Long studentId, Long subjectId, String subSkill);

    /**
     * Wipe all of a student's mastery cells. Used by
     * {@code SkillMasteryService.rebuildForStudent} to re-derive BKT state from
     * scratch (keeps the rebuild idempotent — no double-counted observations).
     */
    void deleteByStudentId(Long studentId);
}
