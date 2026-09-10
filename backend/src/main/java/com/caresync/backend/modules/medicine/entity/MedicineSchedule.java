package com.caresync.backend.modules.medicine.entity;

import com.caresync.backend.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Entity
@Table(name = "medicine_schedules")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MedicineSchedule extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "medicine_id", nullable = false)
    private Medicine medicine;

    @Column(nullable = false)
    private String frequency;

    @Column(columnDefinition = "jsonb")
    private String daysOfWeek;

    @Column(columnDefinition = "jsonb", nullable = false)
    private String scheduledTimes;

    @Column(nullable = false)
    @Builder.Default
    private BigDecimal dosagePerIntake = BigDecimal.ONE;

    @Column(nullable = false)
    @Builder.Default
    private boolean isActive = true;
}
