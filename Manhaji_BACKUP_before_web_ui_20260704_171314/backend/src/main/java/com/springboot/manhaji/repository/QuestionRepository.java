package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.Question;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface QuestionRepository extends JpaRepository<Question, Long> {
    List<Question> findByLessonIdOrderByIdAsc(Long lessonId);
    List<Question> findByLessonId(Long lessonId);
    List<Question> findByLessonIdAndDifficultyLevel(Long lessonId, Integer difficultyLevel);

    @Query(value = """
            SELECT q.*
            FROM questions q
            JOIN lessons l ON q.lesson_id = l.id
            WHERE l.subject_id = :subjectId
            ORDER BY l.order_index ASC, q.id ASC
            """, nativeQuery = true)
    List<Question> findAllBySubjectIdWithLesson(@Param("subjectId") Long subjectId);
}
