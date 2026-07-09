package com.springboot.manhaji.entity;

import com.springboot.manhaji.entity.enums.AttemptStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Check;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "attempts",
        indexes = {
                @Index(name = "idx_attempt_student", columnList = "student_id"),
                @Index(name = "idx_attempt_quiz", columnList = "quiz_id"),
                @Index(name = "idx_attempt_student_quiz_status", columnList = "student_id, quiz_id, status"),
                @Index(name = "idx_attempt_assignment_student", columnList = "quiz_assignment_id, student_id")
        })
// Audit fix (2026-05-15): score is a percentage. Anything outside 0..100 is a
// scoring-engine bug, and silently storing it would corrupt rankings and the
// MASTERED status threshold. NULL is allowed for IN_PROGRESS attempts.
@Check(constraints = "score IS NULL OR score BETWEEN 0 AND 100")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Attempt {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column
    private LocalDateTime submittedAt;

    @Column
    private Double score;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AttemptStatus status = AttemptStatus.IN_PROGRESS;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "quiz_id", nullable = false)
    private Quiz quiz;

    /**
     * Nullable for all existing lesson/adaptive/personalized attempts. Future
     * assigned-quiz starts will set this to connect the result to a published
     * teacher assignment.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "quiz_assignment_id")
    private QuizAssignment quizAssignment;

    @OneToMany(mappedBy = "attempt", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<StudentResponse> responses = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
