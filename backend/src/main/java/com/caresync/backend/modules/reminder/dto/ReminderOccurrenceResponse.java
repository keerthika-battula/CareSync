package com.caresync.backend.modules.reminder.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReminderOccurrenceResponse {
    private UUID id;
    private UUID medicineId;
    private String medicineName;
    private String dosage;
    private BigDecimal dosagePerIntake;
    private String dosageUnit;
    private Integer currentStock;
    private Integer refillThreshold;
    private LocalDateTime scheduledTime;
    private LocalDateTime originalScheduledTime;
    private LocalDateTime snoozedUntil;
    private String status; // PENDING, SNOOZED, TAKEN, SKIPPED
    private LocalDateTime actionTime;
    private Integer snoozeCount;
}
