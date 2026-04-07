package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
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
