package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.QuizAssignment;
import com.springboot.manhaji.entity.enums.QuizAssignmentStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface QuizAssignmentRepository extends JpaRepository<QuizAssignment, Long> {
    boolean existsByQuizId(Long quizId);
    List<QuizAssignment> findByQuizId(Long quizId);
    List<QuizAssignment> findByTeacherIdAndStatus(Long teacherId, QuizAssignmentStatus status);
}
