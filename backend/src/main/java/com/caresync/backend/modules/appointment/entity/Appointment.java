package com.caresync.backend.modules.appointment.entity;

import com.caresync.backend.common.entity.BaseEntity;
import com.caresync.backend.modules.family.entity.FamilyMember;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalTime;

@Entity
@Table(name = "appointments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Appointment extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "family_member_id", nullable = false)
    private FamilyMember familyMember;

    private String doctorName;
    private String hospitalClinic;

    @Column(nullable = false)
    private LocalDate appointmentDate;

    @Column(nullable = false)
    private LocalTime appointmentTime;

    private String purpose;
    private String notes;

    @Column(nullable = false)
    @Builder.Default
    private String status = "UPCOMING"; // UPCOMING, COMPLETED, CANCELLED

    @Builder.Default
    private Integer reminderMinutesBefore = 60;
}
