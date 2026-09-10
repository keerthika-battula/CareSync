package com.caresync.backend.modules.appointment.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

@Data
public class AppointmentRequest {
    private UUID familyMemberId;
    private String doctorName;
    private String hospitalClinic;
    @NotNull(message = "Appointment date is required")
    private LocalDate appointmentDate;
    @NotNull(message = "Appointment time is required")
    private LocalTime appointmentTime;
    private String purpose;
    private String notes;
    private Integer reminderMinutesBefore;
}
