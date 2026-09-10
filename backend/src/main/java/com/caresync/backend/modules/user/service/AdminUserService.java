package com.caresync.backend.modules.user.service;

import com.caresync.backend.common.exception.BadRequestException;
import com.caresync.backend.common.exception.ConflictException;
import com.caresync.backend.common.exception.ResourceNotFoundException;
import com.caresync.backend.common.response.PageResponse;
import com.caresync.backend.modules.appointment.dto.AppointmentResponse;
import com.caresync.backend.modules.appointment.repository.AppointmentRepository;
import com.caresync.backend.modules.appointment.service.AppointmentService;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.model.Role;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.document.dto.DocumentResponse;
import com.caresync.backend.modules.document.repository.DocumentRepository;
import com.caresync.backend.modules.document.service.DocumentService;
import com.caresync.backend.modules.family.dto.FamilyMemberResponse;
import com.caresync.backend.modules.family.repository.FamilyMemberRepository;
import com.caresync.backend.modules.medicine.dto.MedicineResponse;
import com.caresync.backend.modules.medicine.repository.MedicineRepository;
import com.caresync.backend.modules.medicine.service.MedicineService;
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
    private final AppointmentRepository appointmentRepository;
    private final DocumentRepository documentRepository;
    private final MedicineService medicineService;
    private final DocumentService documentService;
    private final AppointmentService appointmentService;

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
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ConflictException("Email is already registered");
        }

        Role role = request.getRole() != null ? request.getRole() : Role.USER;

        User user = User.builder()
                .firstName(request.getFirstName().trim())
                .lastName(request.getLastName().trim())
                .email(request.getEmail().trim().toLowerCase())
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
}
