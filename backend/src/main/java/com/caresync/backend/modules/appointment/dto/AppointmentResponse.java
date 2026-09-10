package com.caresync.backend.modules.appointment.dto;

import com.caresync.backend.modules.appointment.entity.Appointment;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

@Data
@Builder
public class AppointmentResponse {
    private UUID id;
    private UUID familyMemberId;
    private String familyMemberName;
    private String doctorName;
    private String hospitalClinic;
    private LocalDate appointmentDate;
    private LocalTime appointmentTime;
    private String purpose;
    private String notes;
    private String status;
    private Integer reminderMinutesBefore;

    public static AppointmentResponse fromEntity(Appointment a) {
        return AppointmentResponse.builder()
                .id(a.getId())
                .familyMemberId(a.getFamilyMember() != null ? a.getFamilyMember().getId() : null)
                .familyMemberName(a.getFamilyMember() != null ? a.getFamilyMember().getName() : "Self")
                .doctorName(a.getDoctorName())
                .hospitalClinic(a.getHospitalClinic())
                .appointmentDate(a.getAppointmentDate())
                .appointmentTime(a.getAppointmentTime())
                .purpose(a.getPurpose())
                .notes(a.getNotes())
                .status(a.getStatus())
                .reminderMinutesBefore(a.getReminderMinutesBefore())
                .build();
    }
}
