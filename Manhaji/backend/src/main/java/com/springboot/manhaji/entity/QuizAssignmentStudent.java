package com.springboot.manhaji.entity;

import com.springboot.manhaji.entity.enums.QuizAssignmentStudentStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "quiz_assignment_students",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_quiz_assignment_student",
                columnNames = {"quiz_assignment_id", "student_id"}
        ),
        indexes = {
                @Index(name = "idx_quiz_assignment_student_student", columnList = "student_id"),
                @Index(name = "idx_quiz_assignment_student_status", columnList = "status")
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class QuizAssignmentStudent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "quiz_assignment_id", nullable = false)
    private QuizAssignment quizAssignment;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @Column(nullable = false, updatable = false)
    private LocalDateTime assignedAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private QuizAssignmentStudentStatus status = QuizAssignmentStudentStatus.ASSIGNED;

    @PrePersist
    protected void onCreate() {
        if (this.assignedAt == null) {
            this.assignedAt = LocalDateTime.now();
        }
    }
}
