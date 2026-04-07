package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@DiscriminatorValue("PARENT")
@Getter
@Setter
@NoArgsConstructor
public class Parent extends User {

    @OneToMany(mappedBy = "parent", cascade = CascadeType.ALL)
    private List<Student> children = new ArrayList<>();
}
