package com.caresync.backend.modules.user.service;

import com.caresync.backend.common.exception.BadRequestException;
import com.caresync.backend.common.exception.ConflictException;
import com.caresync.backend.common.exception.ResourceNotFoundException;
import com.caresync.backend.common.response.PageResponse;
import com.caresync.backend.modules.appointment.dto.AppointmentResponse;
import com.caresync.backend.modules.appointment.entity.Appointment;
import com.caresync.backend.modules.appointment.repository.AppointmentRepository;
import com.caresync.backend.modules.appointment.service.AppointmentService;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.model.Role;
import com.caresync.backend.modules.auth.repository.PasswordResetTokenRepository;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.document.dto.DocumentResponse;
import com.caresync.backend.modules.document.entity.HealthcareDocument;
import com.caresync.backend.modules.document.repository.DocumentRepository;
import com.caresync.backend.modules.document.service.DocumentService;
import com.caresync.backend.modules.document.service.MinioService;
import com.caresync.backend.modules.family.dto.FamilyMemberResponse;
import com.caresync.backend.modules.family.entity.FamilyMember;
import com.caresync.backend.modules.family.repository.FamilyMemberRepository;
import com.caresync.backend.modules.medicine.dto.MedicineResponse;
import com.caresync.backend.modules.medicine.entity.Medicine;
import com.caresync.backend.modules.medicine.repository.MedicineRepository;
import com.caresync.backend.modules.medicine.repository.MedicineScheduleRepository;
import com.caresync.backend.modules.medicine.repository.RefillAlertRepository;
import com.caresync.backend.modules.medicine.repository.StockTransactionRepository;
import com.caresync.backend.modules.medicine.service.MedicineService;
import com.caresync.backend.modules.notification.repository.FcmTokenRepository;
import com.caresync.backend.modules.reminder.repository.ReminderOccurrenceRepository;
import com.caresync.backend.modules.user.dto.AdminCreateUserRequest;
import com.caresync.backend.modules.user.dto.AdminUserHealthcareOverviewResponse;
import com.caresync.backend.modules.user.dto.AdminUserResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminUserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final FamilyMemberRepository familyMemberRepository;
    private final MedicineRepository medicineRepository;
    private final MedicineScheduleRepository medicineScheduleRepository;
    private final ReminderOccurrenceRepository reminderOccurrenceRepository;
    private final RefillAlertRepository refillAlertRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final AppointmentRepository appointmentRepository;
    private final DocumentRepository documentRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final FcmTokenRepository fcmTokenRepository;
    private final MedicineService medicineService;
    private final DocumentService documentService;
    private final AppointmentService appointmentService;
    private final MinioService minioService;

    @Transactional(readOnly = true)
    public PageResponse<AdminUserResponse> getAllUsers(Pageable pageable) {
        Page<User> page = userRepository.findAll(pageable);
        return PageResponse.from(page.map(AdminUserResponse::fromEntity));
    }

    @Transactional(readOnly = true)
    public AdminUserResponse getUserById(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));
        return AdminUserResponse.fromEntity(user);
    }

    @Transactional
    public AdminUserResponse createUser(AdminCreateUserRequest request) {
        String email = request.getEmail() != null ? request.getEmail().trim() : "";
        if (userRepository.existsByEmail(email) || userRepository.existsByEmailIgnoreCase(email)) {
            throw new ConflictException("Email is already registered");
        }

        String username = request.getUsername() != null && !request.getUsername().trim().isEmpty()
                ? request.getUsername().trim().toLowerCase()
                : null;

        if (username != null && userRepository.existsByUsernameIgnoreCase(username)) {
            throw new ConflictException("Username is already taken");
        }

        Role role = request.getRole() != null ? request.getRole() : Role.USER;

        User user = User.builder()
                .firstName(request.getFirstName().trim())
                .lastName(request.getLastName().trim())
                .email(request.getEmail().trim().toLowerCase())
                .username(username)
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .phoneNumber(request.getPhoneNumber() != null ? request.getPhoneNumber().trim() : null)
                .role(role)
                .isActive(true)
                .isEmailVerified(false)
                .build();

        User saved = userRepository.save(user);
        return AdminUserResponse.fromEntity(saved);
    }

    @Transactional
    public AdminUserResponse updateUserRole(UUID userId, Role newRole) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        if (user.getRole() == Role.ADMIN && newRole != Role.ADMIN && user.isActive()) {
            List<User> activeAdmins = userRepository.findAllActiveAdminsForUpdate(Role.ADMIN);
            if (activeAdmins.size() <= 1) {
                throw new BadRequestException("Cannot demote the last active administrator. System must always have at least one active admin.");
            }
        }

        user.setRole(newRole);
        User saved = userRepository.save(user);
        return AdminUserResponse.fromEntity(saved);
    }

    @Transactional
    public AdminUserResponse updateUserStatus(UUID userId, boolean isActive) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        if (user.getRole() == Role.ADMIN && user.isActive() && !isActive) {
            List<User> activeAdmins = userRepository.findAllActiveAdminsForUpdate(Role.ADMIN);
            if (activeAdmins.size() <= 1) {
                throw new BadRequestException("Cannot deactivate the last active administrator. System must always have at least one active admin.");
            }
        }

        user.setActive(isActive);
        User saved = userRepository.save(user);
        return AdminUserResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public AdminUserHealthcareOverviewResponse getUserHealthcareOverview(UUID userId) {
        if (!userRepository.existsById(userId)) {
            throw new ResourceNotFoundException("User not found with id: " + userId);
        }

        long familyMembersCount = familyMemberRepository.findAllByUserId(userId).size();
        long activeMedicinesCount = medicineRepository.findAllByFamilyMemberUserIdAndIsActiveTrue(userId).size();
        long upcomingAppointmentsCount = appointmentRepository
                .findAllByFamilyMemberUserIdAndAppointmentDateGreaterThanEqualAndStatus(userId, LocalDate.now(), "UPCOMING")
                .size();
        long totalDocsCount = documentRepository.findAllByFamilyMemberUserId(userId).size();

        return AdminUserHealthcareOverviewResponse.builder()
                .userId(userId)
                .familyMembersCount(familyMembersCount)
                .activeMedicinesCount(activeMedicinesCount)
                .upcomingAppointmentsCount(upcomingAppointmentsCount)
                .totalDocumentsCount(totalDocsCount)
                .build();
    }

    @Transactional(readOnly = true)
    public List<MedicineResponse> getUserMedicines(UUID userId) {
        if (!userRepository.existsById(userId)) {
            throw new ResourceNotFoundException("User not found with id: " + userId);
        }
        return medicineService.getMedicinesForUser(userId);
    }

    @Transactional(readOnly = true)
    public List<DocumentResponse> getUserDocuments(UUID userId) {
        if (!userRepository.existsById(userId)) {
            throw new ResourceNotFoundException("User not found with id: " + userId);
        }
        return documentService.getDocumentsForUser(userId);
    }

    @Transactional(readOnly = true)
    public DocumentService.DocumentDownload downloadUserDocument(UUID userId, UUID documentId) throws Exception {
        if (!userRepository.existsById(userId)) {
            throw new ResourceNotFoundException("User not found with id: " + userId);
        }
        return documentService.downloadDocumentForAdmin(userId, documentId);
    }

    @Transactional(readOnly = true)
    public List<FamilyMemberResponse> getUserFamilyMembers(UUID userId) {
        if (!userRepository.existsById(userId)) {
            throw new ResourceNotFoundException("User not found with id: " + userId);
        }
        return familyMemberRepository.findAllByUserId(userId).stream()
                .map(m -> FamilyMemberResponse.builder()
                        .id(m.getId())
                        .name(m.getName())
                        .relationship(m.getRelationship())
                        .dateOfBirth(m.getDateOfBirth())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<AppointmentResponse> getUserAppointments(UUID userId) {
        if (!userRepository.existsById(userId)) {
            throw new ResourceNotFoundException("User not found with id: " + userId);
        }
        return appointmentService.getAppointmentsForUser(userId);
    }

    @Transactional
    public void deleteUser(UUID userId, User currentAdmin) {
        if (currentAdmin != null && currentAdmin.getId().equals(userId)) {
            throw new BadRequestException("Administrators cannot remove their own account.");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        if (user.getRole() == Role.ADMIN && user.isActive()) {
            List<User> activeAdmins = userRepository.findAllActiveAdminsForUpdate(Role.ADMIN);
            if (activeAdmins.size() <= 1) {
                throw new BadRequestException("The last active administrator cannot be removed.");
            }
        }

        // 1. Clean up tokens & reminder occurrences
        fcmTokenRepository.deleteAllByUserId(userId);
        passwordResetTokenRepository.deleteAllByUser(user);
        reminderOccurrenceRepository.deleteAllByUserId(userId);

        // 2. Clean up family members and their healthcare records
        List<FamilyMember> familyMembers = familyMemberRepository.findAllByUserId(userId);
        for (FamilyMember fm : familyMembers) {
            // Delete medicines and sub-entities
            List<Medicine> medicines = medicineRepository.findAllByFamilyMemberId(fm.getId());
            for (Medicine med : medicines) {
                reminderOccurrenceRepository.deleteAllByMedicineId(med.getId());
                medicineScheduleRepository.deleteAllByMedicineId(med.getId());
                refillAlertRepository.deleteAllByMedicineId(med.getId());
                stockTransactionRepository.deleteAllByMedicineId(med.getId());
                medicineRepository.delete(med);
            }

            // Delete documents & remove MinIO storage files
            List<HealthcareDocument> docs = documentRepository.findAllByFamilyMemberId(fm.getId());
            for (HealthcareDocument doc : docs) {
                try {
                    if (doc.getFilePath() != null) {
                        minioService.deleteFile(doc.getFilePath());
                    }
                } catch (Exception ignored) {
                }
                documentRepository.delete(doc);
            }

            // Delete appointments
            List<Appointment> appointments = appointmentRepository.findAllByFamilyMemberId(fm.getId());
            appointmentRepository.deleteAll(appointments);

            // Delete family member
            familyMemberRepository.delete(fm);
        }

        // 3. Delete user account
        userRepository.delete(user);
    }
}
