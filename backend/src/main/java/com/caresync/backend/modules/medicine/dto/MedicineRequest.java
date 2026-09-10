package com.caresync.backend.modules.medicine.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Data
public class MedicineRequest {
    @NotBlank(message = "Medicine name is required")
    private String name;
    
    private String dosage;
    private String frequency;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer currentQuantity;
    private Integer refillThreshold;
    private String notes;
    private UUID familyMemberId;
    
    private List<ScheduleRequest> schedules;

    @Data
    public static class ScheduleRequest {
        private String scheduledTime; // HH:mm format
        private List<Integer> daysOfWeek; // 1-7 (Mon-Sun)
    }
}
