package com.caresync.backend.modules.medicine.entity;

import com.caresync.backend.common.entity.BaseEntity;
import com.caresync.backend.modules.family.entity.FamilyMember;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Entity
@Table(name = "medicines")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Medicine extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "family_member_id", nullable = false)
    private FamilyMember familyMember;

    @Column(nullable = false)
    private String name;

    private String dosage;

    private String dosageUnit;

    private String instructions;

    @Column(nullable = false)
    private LocalDate startDate;

    private LocalDate endDate;

    @Column(nullable = false)
    @Builder.Default
    private boolean isActive = true;

    @Column(nullable = false)
    @Builder.Default
    private boolean isOngoing = false;

    private Integer currentStock;

    @Builder.Default
    private Integer refillThreshold = 7;
}
