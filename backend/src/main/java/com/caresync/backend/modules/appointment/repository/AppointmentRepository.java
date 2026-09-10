package com.caresync.backend.modules.appointment.repository;

import com.caresync.backend.modules.appointment.entity.Appointment;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;
import java.time.LocalDate;

public interface AppointmentRepository extends JpaRepository<Appointment, UUID> {
    List<Appointment> findAllByFamilyMemberUserId(UUID userId);
    List<Appointment> findAllByFamilyMemberUserIdAndAppointmentDate(UUID userId, LocalDate date);
    List<Appointment> findAllByFamilyMemberUserIdAndAppointmentDateGreaterThanEqualAndStatus(UUID userId, LocalDate date, String status);
    List<Appointment> findAllByFamilyMemberUserIdAndAppointmentDateLessThanAndStatus(UUID userId, LocalDate date, String status);
}
