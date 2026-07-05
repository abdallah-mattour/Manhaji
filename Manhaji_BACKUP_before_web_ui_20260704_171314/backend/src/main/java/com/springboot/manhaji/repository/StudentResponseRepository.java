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
}
