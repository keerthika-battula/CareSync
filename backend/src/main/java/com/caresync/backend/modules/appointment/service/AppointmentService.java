package com.caresync.backend.modules.appointment.service;

import com.caresync.backend.modules.appointment.entity.Appointment;
import com.caresync.backend.modules.appointment.repository.AppointmentRepository;
import com.caresync.backend.modules.family.entity.FamilyMember;
import com.caresync.backend.modules.family.repository.FamilyMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AppointmentService {

    private final AppointmentRepository appointmentRepository;
    private final FamilyMemberRepository familyMemberRepository;

    @Transactional
    public Appointment createAppointment(UUID userId, Appointment appointmentReq, UUID familyMemberId) {
        FamilyMember familyMember = familyMemberRepository.findById(familyMemberId).orElseThrow();
        if (!familyMember.getUser().getId().equals(userId)) throw new SecurityException("Unauthorized");

        Appointment appointment = Appointment.builder()
                .familyMember(familyMember)
                .doctorName(appointmentReq.getDoctorName())
                .hospitalClinic(appointmentReq.getHospitalClinic())
                .appointmentDate(appointmentReq.getAppointmentDate())
                .appointmentTime(appointmentReq.getAppointmentTime())
                .purpose(appointmentReq.getPurpose())
                .notes(appointmentReq.getNotes())
                .build();

        return appointmentRepository.save(appointment);
    }

    @Transactional(readOnly = true)
    public List<Appointment> getUpcoming(UUID userId) {
        return appointmentRepository.findAllByFamilyMemberUserIdAndAppointmentDateGreaterThanEqualAndStatus(userId, LocalDate.now(), "UPCOMING");
    }

    @Transactional
    public void deleteAppointment(UUID userId, UUID appointmentId) {
        Appointment app = appointmentRepository.findById(appointmentId).orElseThrow();
        if (!app.getFamilyMember().getUser().getId().equals(userId)) throw new SecurityException("Unauthorized");
        appointmentRepository.delete(app);
    }
}
