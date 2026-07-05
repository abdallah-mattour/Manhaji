package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

/**
 * Parent profile. Holds no scalar columns of its own — the parent↔child
 * relationship lives on {@link Student#getParent()} (FK
 * {@code students.parent_id} → {@code parents.id} ← shared with
 * {@code users.id}). The {@code parents} table is essentially an
 * inheritance marker; that's fine — JOINED inheritance still benefits us by
 * keeping the unused student-only columns out of every parent row.
 */
@Entity
@Table(name = "parents")
@DiscriminatorValue("PARENT")
@Getter
@Setter
@NoArgsConstructor
public class Parent extends User {

    /**
     * Audit fix (2026-05-15): cascade was previously {@code CascadeType.ALL},
     * which meant deleting a parent account also deleted every child and all
     * their attempts, progress, responses, and learning path — catastrophic
     * data loss. Replaced with PERSIST + MERGE so saving a parent still saves
     * pending children, but a parent delete leaves {@code Student.parent}
     * null on the existing rows (the column is already nullable).
     */
    @OneToMany(mappedBy = "parent", cascade = {CascadeType.PERSIST, CascadeType.MERGE})
    private List<Student> children = new ArrayList<>();
}
