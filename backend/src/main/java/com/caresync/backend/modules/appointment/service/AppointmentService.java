package com.caresync.backend.modules.appointment.service;

import com.caresync.backend.common.exception.ForbiddenException;
import com.caresync.backend.common.exception.ResourceNotFoundException;
import com.caresync.backend.modules.appointment.dto.AppointmentRequest;
import com.caresync.backend.modules.appointment.dto.AppointmentResponse;
import com.caresync.backend.modules.appointment.entity.Appointment;
import com.caresync.backend.modules.appointment.repository.AppointmentRepository;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.family.entity.FamilyMember;
import com.caresync.backend.modules.family.repository.FamilyMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AppointmentService {

    private final AppointmentRepository appointmentRepository;
    private final FamilyMemberRepository familyMemberRepository;
    private final UserRepository userRepository;

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
                .status("UPCOMING")
                .reminderMinutesBefore(appointmentReq.getReminderMinutesBefore() != null ? appointmentReq.getReminderMinutesBefore() : 60)
                .build();

        return appointmentRepository.save(appointment);
    }

    @Transactional(readOnly = true)
    public List<Appointment> getUpcoming(UUID userId) {
        return appointmentRepository.findAllByFamilyMemberUserIdAndAppointmentDateGreaterThanEqualAndStatus(
                userId, LocalDate.now(), "UPCOMING");
    }

    @Transactional
    public void deleteAppointment(UUID userId, UUID appointmentId) {
        Appointment app = appointmentRepository.findById(appointmentId).orElseThrow();
        if (!app.getFamilyMember().getUser().getId().equals(userId)) throw new SecurityException("Unauthorized");
        appointmentRepository.delete(app);
    }

    @Transactional
    public AppointmentResponse createAppointment(String email, AppointmentRequest req) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        FamilyMember familyMember;
        if (req.getFamilyMemberId() != null) {
            familyMember = familyMemberRepository.findById(req.getFamilyMemberId())
                    .orElseThrow(() -> new ResourceNotFoundException("Family member not found"));
            if (!familyMember.getUser().getId().equals(user.getId())) {
                throw new ForbiddenException("Unauthorized to create appointment for this family member");
            }
        } else {
            familyMember = getOrCreateSelfFamilyMember(user);
        }

        Appointment appointment = Appointment.builder()
                .familyMember(familyMember)
                .doctorName(req.getDoctorName() != null ? req.getDoctorName().trim() : null)
                .hospitalClinic(req.getHospitalClinic() != null ? req.getHospitalClinic().trim() : null)
                .appointmentDate(req.getAppointmentDate())
                .appointmentTime(req.getAppointmentTime())
                .purpose(req.getPurpose() != null ? req.getPurpose().trim() : null)
                .notes(req.getNotes())
                .status("UPCOMING")
                .reminderMinutesBefore(req.getReminderMinutesBefore() != null ? req.getReminderMinutesBefore() : 60)
                .build();

        Appointment saved = appointmentRepository.save(appointment);
        return AppointmentResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<AppointmentResponse> getUpcoming(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return appointmentRepository.findAllByFamilyMemberUserIdAndAppointmentDateGreaterThanEqualAndStatus(
                user.getId(), LocalDate.now(), "UPCOMING")
                .stream()
                .map(AppointmentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public void deleteAppointment(String email, UUID appointmentId) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Appointment app = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment not found"));

        if (!app.getFamilyMember().getUser().getId().equals(user.getId())) {
            throw new ForbiddenException("Unauthorized to delete this appointment");
        }

        appointmentRepository.delete(app);
    }

    @Transactional(readOnly = true)
    public List<AppointmentResponse> getAppointmentsForUser(UUID userId) {
        return appointmentRepository.findAllByFamilyMemberUserId(userId)
                .stream()
                .map(AppointmentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    private FamilyMember getOrCreateSelfFamilyMember(User user) {
        return familyMemberRepository.findByUserIdAndIsSelfTrue(user.getId())
                .orElseGet(() -> {
                    String name = (user.getFirstName() != null ? user.getFirstName() : "") + " " +
                            (user.getLastName() != null ? user.getLastName() : "");
                    name = name.trim();
                    if (name.isEmpty()) {
                        name = "Myself";
                    }
                    FamilyMember selfMember = FamilyMember.builder()
                            .user(user)
                            .name(name)
                            .relationship("Self")
                            .isSelf(true)
                            .build();
                    return familyMemberRepository.save(selfMember);
                });
    }
}
