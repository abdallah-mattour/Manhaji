package com.springboot.manhaji.entity;

import com.springboot.manhaji.entity.enums.QuizAssignmentStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "quiz_assignments",
        indexes = {
                @Index(name = "idx_quiz_assignment_quiz", columnList = "quiz_id"),
                @Index(name = "idx_quiz_assignment_teacher", columnList = "teacher_id"),
                @Index(name = "idx_quiz_assignment_scope",
                        columnList = "subject_id, school_id, grade_level, status")
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class QuizAssignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "quiz_id", nullable = false)
    private Quiz quiz;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "teacher_id", nullable = false)
    private Teacher teacher;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "subject_id", nullable = false)
    private Subject subject;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;

    @Column(name = "grade_level", nullable = false)
    private Integer gradeLevel;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private QuizAssignmentStatus status = QuizAssignmentStatus.PUBLISHED;

    @Column(nullable = false)
    private LocalDateTime publishedAt;

    @Column
    private LocalDateTime dueAt;

    @Column
    private Integer maxAttempts;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @OneToMany(mappedBy = "quizAssignment", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<QuizAssignmentStudent> students = new ArrayList<>();

    @OneToMany(mappedBy = "quizAssignment")
    private List<Attempt> attempts = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        if (this.publishedAt == null) {
            this.publishedAt = now;
        }
    }
}
