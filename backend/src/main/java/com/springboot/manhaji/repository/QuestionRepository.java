package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.Question;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface QuestionRepository extends JpaRepository<Question, Long> {
    List<Question> findByLessonIdOrderByIdAsc(Long lessonId);
    List<Question> findByLessonId(Long lessonId);
    List<Question> findByLessonIdAndDifficultyLevel(Long lessonId, Integer difficultyLevel);
}
