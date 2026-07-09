package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.StudentResponse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StudentResponseRepository extends JpaRepository<StudentResponse, Long> {
    List<StudentResponse> findByAttemptId(Long attemptId);

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
