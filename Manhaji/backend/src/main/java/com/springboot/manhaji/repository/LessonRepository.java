package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.Lesson;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LessonRepository extends JpaRepository<Lesson, Long> {
    List<Lesson> findBySubjectIdOrderByOrderIndexAsc(Long subjectId);
    List<Lesson> findByGradeLevelOrderByOrderIndexAsc(Integer gradeLevel);
    List<Lesson> findBySubjectIdAndGradeLevelOrderByOrderIndexAsc(Long subjectId, Integer gradeLevel);

    @Query("""
            SELECT l FROM Lesson l
            JOIN FETCH l.subject s
            WHERE s.id IN :subjectIds
              AND l.gradeLevel = :gradeLevel
            ORDER BY s.id ASC, l.orderIndex ASC
            """)
    List<Lesson> findBySubjectIdsAndGradeLevel(
            @Param("subjectIds") List<Long> subjectIds,
            @Param("gradeLevel") Integer gradeLevel);
}
