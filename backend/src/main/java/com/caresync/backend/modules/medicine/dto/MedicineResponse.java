package com.caresync.backend.modules.medicine.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

@Data
@Builder
public class MedicineResponse {
    private UUID id;
    private String name;
    private String dosage;
    private String frequency;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer currentQuantity;
    private Integer refillThreshold;
    private String notes;
    private boolean isActive;
    private UUID familyMemberId;
    private List<ScheduleResponse> schedules;

    @Data
    @Builder
    public static class ScheduleResponse {
        private UUID id;
        private LocalTime scheduledTime;
        private List<Integer> daysOfWeek;
    }
}
