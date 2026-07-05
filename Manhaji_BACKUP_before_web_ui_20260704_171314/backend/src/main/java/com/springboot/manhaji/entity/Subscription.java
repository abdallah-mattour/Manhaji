package com.springboot.manhaji.entity;

import com.springboot.manhaji.entity.enums.SubscriptionStatus;
import com.springboot.manhaji.entity.enums.SubscriptionType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Check;

import java.time.LocalDate;

@Entity
@Table(name = "subscriptions")
// Audit fix (2026-05-15): a subscription's endDate must be on or after its
// startDate. Without this, an off-by-one or swapped-order bug in a service
// could silently create a "negative-length" subscription that breaks billing
// and active-period queries.
@Check(constraints = "end_date >= start_date")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Subscription {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private LocalDate startDate;

    @Column(nullable = false)
    private LocalDate endDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SubscriptionStatus status = SubscriptionStatus.TRIAL;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SubscriptionType subscriptionType;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id", nullable = false)
    private School school;
}
