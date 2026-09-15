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
import lombok.extern.slf4j.Slf4j;
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

@Slf4j
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
    public PageResponse<AdminUserResponse> getAllUsers(Boolean activeOnly, Pageable pageable) {
        Page<User> page;
        if (activeOnly != null) {
            page = userRepository.findAllByIsActive(activeOnly, pageable);
        } else {
            page = userRepository.findAll(pageable);
        }
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
    public String deleteUser(UUID userId, User currentAdmin) {
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

        // 1. Invalidate authentication tokens & active sessions
        try {
            fcmTokenRepository.deleteAllByUserId(userId);
        } catch (Exception e) {
            log.warn("Could not delete FCM tokens for user {}: {}", userId, e.getMessage());
        }
        try {
            passwordResetTokenRepository.deleteAllByUser(user);
        } catch (Exception e) {
            log.warn("Could not delete password reset tokens for user {}: {}", userId, e.getMessage());
        }

        // 2. Check if user has dependent healthcare records
        List<FamilyMember> familyMembers = familyMemberRepository.findAllByUserId(userId);
        long medicines = medicineRepository.findAllByFamilyMemberUserId(userId).size();
        long docs = documentRepository.findAllByFamilyMemberUserId(userId).size();
        long appts = appointmentRepository.findAllByFamilyMemberUserId(userId).size();

        boolean hasHealthcareData = (medicines > 0 || docs > 0 || appts > 0);

        if (hasHealthcareData) {
            // Patient safety & data integrity: Soft-delete/deactivate account
            log.info("User {} has healthcare records (medicines={}, docs={}, appts={}). Applying soft deletion/deactivation.",
                    userId, medicines, docs, appts);
            user.setActive(false);
            userRepository.save(user);
            return "User account deactivated successfully; healthcare records were preserved.";
        } else {
            // Clean deletion of empty user / test account
            try {
                reminderOccurrenceRepository.deleteAllByUserId(userId);
                for (FamilyMember fm : familyMembers) {
                    familyMemberRepository.delete(fm);
                }
                userRepository.delete(user);
                log.info("User {} successfully removed permanently.", userId);
                return "User account deleted successfully.";
            } catch (Exception e) {
                // Safe fallback to deactivation if any DB constraints or relations exist
                log.warn("Permanent deletion could not complete for user {}, falling back to deactivation: {}", userId, e.getMessage());
                user.setActive(false);
                userRepository.save(user);
                return "User account deactivated successfully; healthcare records were preserved.";
            }
        }
    }
}
