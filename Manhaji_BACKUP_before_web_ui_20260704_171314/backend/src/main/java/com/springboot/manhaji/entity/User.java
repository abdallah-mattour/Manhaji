package com.springboot.manhaji.entity;

import com.springboot.manhaji.entity.enums.Role;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Check;

import java.time.LocalDateTime;

@Entity
@Table(name = "users", indexes = {
        @Index(name = "idx_user_role", columnList = "role")
        // Refactor (2026-05-26): migrated from SINGLE_TABLE to JOINED inheritance.
        // The previous indexes on parent_id / school_id / (school_id, grade_level)
        // referenced columns that now live in the per-role child tables
        // (`students`, `teachers`). They've been moved to their respective
        // subclass entities' @Table.indexes — see Student.java and Teacher.java.
})
// Refactor (2026-05-26): JOINED inheritance. `users` keeps the shared identity
// columns (id, email, phone, password_hash, role, isActive, lastLoginAt,
// createdAt). Each role's specific columns live in its own child table
// (`students`, `teachers`, `parents`, `admins`), with the PK doubling as an
// FK back to `users.id`. Existing FKs from `attempts`, `progress`,
// `student_responses`, etc. that point at `users.id` continue to work
// unchanged — the student's ID is the same number in both tables.
//
// The discriminator column (`role`) is retained even though JOINED makes it
// optional: with the discriminator Hibernate can determine the subtype from
// the parent row alone, avoiding LEFT JOINs across every subclass table on
// polymorphic loads.
@Inheritance(strategy = InheritanceType.JOINED)
@DiscriminatorColumn(name = "role", discriminatorType = DiscriminatorType.STRING)
// Audit fix (2026-05-15): a user must have at least one of email / phone for
// login. Currently the application validates this in AuthService.register but
// nothing prevents a direct INSERT (or a test fixture) from creating an
// unloggable user. MySQL's UNIQUE permits multiple NULLs so the existing
// unique constraints on email + phone don't enforce this.
@Check(constraints = "email IS NOT NULL OR phone IS NOT NULL")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public abstract class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String fullName;

    @Column(unique = true)
    private String email;

    @Column(unique = true)
    private String phone;

    @Column(nullable = false)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", insertable = false, updatable = false)
    private Role role;

    @Column(nullable = false)
    private Boolean isActive = true;

    private LocalDateTime lastLoginAt;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
