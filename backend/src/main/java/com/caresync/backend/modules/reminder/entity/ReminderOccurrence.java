package com.caresync.backend.modules.reminder.entity;

import com.caresync.backend.common.entity.BaseEntity;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.medicine.entity.Medicine;
import com.caresync.backend.modules.medicine.entity.MedicineSchedule;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "reminder_occurrences")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReminderOccurrence extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "medicine_id", nullable = false)
    private Medicine medicine;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "schedule_id")
    private MedicineSchedule schedule;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private LocalDateTime scheduledTime;

    private LocalDateTime originalScheduledTime;

    private LocalDateTime snoozedUntil;

    @Column(nullable = false)
    @Builder.Default
    private String status = "PENDING"; // PENDING, TAKEN, SKIPPED, SNOOZED

    private LocalDateTime actionTime;

    @Column(nullable = false)
    @Builder.Default
    private Integer snoozeCount = 0;
}
