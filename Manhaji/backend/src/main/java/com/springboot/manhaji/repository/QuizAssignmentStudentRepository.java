package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.QuizAssignmentStudent;
import com.springboot.manhaji.entity.enums.QuizAssignmentStudentStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface QuizAssignmentStudentRepository extends JpaRepository<QuizAssignmentStudent, Long> {
    boolean existsByQuizAssignmentIdAndStudentId(Long quizAssignmentId, Long studentId);
    Optional<QuizAssignmentStudent> findByQuizAssignmentIdAndStudentId(
            Long quizAssignmentId,
            Long studentId);
    List<QuizAssignmentStudent> findByStudentIdAndStatus(
            Long studentId,
            QuizAssignmentStudentStatus status);
}
