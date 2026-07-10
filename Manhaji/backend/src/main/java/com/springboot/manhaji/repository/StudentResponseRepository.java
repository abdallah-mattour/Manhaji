package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.StudentResponse;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StudentResponseRepository extends JpaRepository<StudentResponse, Long> {
    /**
     * All responses in an attempt, oldest first. Explicit ordering matters: BKT
     * ({@code SkillMasteryService.recordResponses}) folds these in sequence and
     * the update is order-sensitive, so we can't rely on the DB's default row
     * order. Ascending id == answer order (StudentResponse has no answered-at).
     */
    @Query("SELECT r FROM StudentResponse r WHERE r.attempt.id = :attemptId ORDER BY r.id ASC")
    List<StudentResponse> findByAttemptId(@Param("attemptId") Long attemptId);

    /**
     * Tier A / A1 (2026-05-15): used by {@code QuizSelectionService} to score
     * questions for Practice Mode. Returns every response the student has ever
     * submitted to any question in the given lesson, across all attempts.
     * Joins through Attempt → Student and Question → Lesson.
     */
    @Query("""
            SELECT r FROM StudentResponse r
            JOIN r.attempt a
            JOIN r.question q
            WHERE a.student.id = :studentId
              AND q.lesson.id = :lessonId
            """)
    List<StudentResponse> findByStudentIdAndLessonId(
            @Param("studentId") Long studentId,
            @Param("lessonId") Long lessonId);

    /**
     * Every graded response a student has ever submitted, oldest first, with the
     * question → lesson → subject graph fetched. Used by
     * {@code SkillMasteryService.rebuildForStudent} to re-fold the whole history
     * through BKT in answer order (attempt order, then within-attempt id order).
     */
    @Query("""
            SELECT r FROM StudentResponse r
            JOIN r.attempt a
            JOIN FETCH r.question q
            JOIN FETCH q.lesson l
            JOIN FETCH l.subject subject
            WHERE a.student.id = :studentId
            ORDER BY a.id ASC, r.id ASC
            """)
    List<StudentResponse> findAllForBktByStudentId(@Param("studentId") Long studentId);

    /**
     * Question ids the student answered MOST RECENTLY in a subject, newest first.
     * Used by {@code QuizSelectionService.selectPersonalized} for the novelty
     * penalty — pass a {@code Pageable} to bound it to the last N responses so
     * "recently seen" stays meaningful (and it's one query, not one per lesson).
     */
    @Query("""
            SELECT q.id FROM StudentResponse r
            JOIN r.attempt a
            JOIN r.question q
            JOIN q.lesson l
            WHERE a.student.id = :studentId
              AND l.subject.id = :subjectId
            ORDER BY a.id DESC, r.id DESC
            """)
    List<Long> findRecentQuestionIdsBySubject(
            @Param("studentId") Long studentId,
            @Param("subjectId") Long subjectId,
            Pageable pageable);

    @Query("""
            SELECT r FROM StudentResponse r
            JOIN FETCH r.attempt a
            JOIN FETCH a.student s
            JOIN FETCH r.question q
            JOIN FETCH q.lesson l
            JOIN FETCH l.subject subject
            WHERE r.isCorrect = false
              AND s.id IN :studentIds
              AND subject.id IN :subjectIds
              AND (:subjectId IS NULL OR subject.id = :subjectId)
              AND (:lessonId IS NULL OR l.id = :lessonId)
              AND (:studentId IS NULL OR s.id = :studentId)
            ORDER BY a.createdAt DESC, r.id DESC
            """)
    List<StudentResponse> findIncorrectByStudentIdsAndSubjectIds(
            @Param("studentIds") List<Long> studentIds,
            @Param("subjectIds") List<Long> subjectIds,
            @Param("subjectId") Long subjectId,
            @Param("lessonId") Long lessonId,
            @Param("studentId") Long studentId);
}
