package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Teacher profile data. With JOINED inheritance, lives in its own table
 * ({@code teachers}) with the PK doubling as an FK to {@code users.id}.
 * The {@code school_id} index supports teacher dashboard queries that scope
 * by school.
 */
@Entity
@Table(name = "teachers", indexes = {
        @Index(name = "idx_teacher_school", columnList = "school_id")
})
@DiscriminatorValue("TEACHER")
@Getter
@Setter
@NoArgsConstructor
public class Teacher extends User {

    @Column
    private String department;

    @Column
    private Integer assignedGrade;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;
}
