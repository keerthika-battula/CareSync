package com.caresync.backend.modules.medicine.service;

import com.caresync.backend.common.exception.ForbiddenException;
import com.caresync.backend.common.exception.ResourceNotFoundException;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.family.entity.FamilyMember;
import com.caresync.backend.modules.family.repository.FamilyMemberRepository;
import com.caresync.backend.modules.medicine.dto.MedicineRequest;
import com.caresync.backend.modules.medicine.dto.MedicineResponse;
import com.caresync.backend.modules.medicine.entity.Medicine;
import com.caresync.backend.modules.medicine.entity.MedicineSchedule;
import com.caresync.backend.modules.medicine.repository.MedicineRepository;
import com.caresync.backend.modules.medicine.repository.MedicineScheduleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MedicineService {

    private final MedicineRepository medicineRepository;
    private final MedicineScheduleRepository scheduleRepository;
    private final UserRepository userRepository;
    private final FamilyMemberRepository familyMemberRepository;

    @Transactional
    public MedicineResponse addMedicine(String email, MedicineRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        FamilyMember familyMember;
        if (request.getFamilyMemberId() != null) {
            familyMember = familyMemberRepository.findById(request.getFamilyMemberId())
                    .orElseThrow(() -> new ResourceNotFoundException("Family member not found"));
            if (!familyMember.getUser().getId().equals(user.getId())) {
                throw new ForbiddenException("You are not authorized to add medicine for this family member");
            }
        } else {
            familyMember = getOrCreateSelfFamilyMember(user);
        }

        Medicine medicine = Medicine.builder()
                .name(request.getName().trim())
                .dosage(request.getDosage() != null ? request.getDosage().trim() : null)
                .familyMember(familyMember)
                .startDate(request.getStartDate() != null ? request.getStartDate() : java.time.LocalDate.now())
                .endDate(request.getEndDate())
                .currentStock(request.getCurrentQuantity() != null ? request.getCurrentQuantity() : 0)
                .refillThreshold(request.getRefillThreshold() != null ? request.getRefillThreshold() : 7)
                .instructions(request.getNotes())
                .isActive(true)
                .build();

        Medicine savedMedicine = medicineRepository.save(medicine);
        return mapToResponse(savedMedicine);
    }

    @Transactional
    public MedicineResponse updateMedicine(String email, UUID medicineId, MedicineRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Medicine medicine = medicineRepository.findById(medicineId)
                .orElseThrow(() -> new ResourceNotFoundException("Medicine not found"));

        if (!medicine.getFamilyMember().getUser().getId().equals(user.getId())) {
            throw new ForbiddenException("You are not authorized to update this medicine");
        }

        if (request.getName() != null && !request.getName().isBlank()) {
            medicine.setName(request.getName().trim());
        }
        if (request.getDosage() != null) {
            medicine.setDosage(request.getDosage().trim());
        }
        if (request.getStartDate() != null) {
            medicine.setStartDate(request.getStartDate());
        }
        if (request.getEndDate() != null) {
            medicine.setEndDate(request.getEndDate());
        }
        if (request.getCurrentQuantity() != null) {
            medicine.setCurrentStock(request.getCurrentQuantity());
        }
        if (request.getRefillThreshold() != null) {
            medicine.setRefillThreshold(request.getRefillThreshold());
        }
        if (request.getNotes() != null) {
            medicine.setInstructions(request.getNotes());
        }
        if (request.getFamilyMemberId() != null) {
            FamilyMember fm = familyMemberRepository.findById(request.getFamilyMemberId())
                    .orElseThrow(() -> new ResourceNotFoundException("Family member not found"));
            if (!fm.getUser().getId().equals(user.getId())) {
                throw new ForbiddenException("You are not authorized to assign this family member");
            }
            medicine.setFamilyMember(fm);
        }

        Medicine updated = medicineRepository.save(medicine);
        return mapToResponse(updated);
    }

    @Transactional
    public void deleteMedicine(String email, UUID medicineId) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Medicine medicine = medicineRepository.findById(medicineId)
                .orElseThrow(() -> new ResourceNotFoundException("Medicine not found"));

        if (!medicine.getFamilyMember().getUser().getId().equals(user.getId())) {
            throw new ForbiddenException("You are not authorized to delete this medicine");
        }

        medicineRepository.delete(medicine);
    }

    @Transactional(readOnly = true)
    public MedicineResponse getMedicineById(String email, UUID medicineId) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Medicine medicine = medicineRepository.findById(medicineId)
                .orElseThrow(() -> new ResourceNotFoundException("Medicine not found"));

        if (!medicine.getFamilyMember().getUser().getId().equals(user.getId())) {
            throw new ForbiddenException("You are not authorized to view this medicine");
        }

        return mapToResponse(medicine);
    }

    @Transactional(readOnly = true)
    public List<MedicineResponse> getAllActiveMedicines(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        List<Medicine> medicines = medicineRepository.findAllByFamilyMemberUserIdAndIsActiveTrue(user.getId());
        return medicines.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<MedicineResponse> getMedicinesForUser(UUID userId) {
        List<Medicine> medicines = medicineRepository.findAllByFamilyMemberUserIdAndIsActiveTrue(userId);
        return medicines.stream().map(this::mapToResponse).collect(Collectors.toList());
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

    private MedicineResponse mapToResponse(Medicine m) {
        return MedicineResponse.builder()
                .id(m.getId())
                .name(m.getName())
                .dosage(m.getDosage())
                .startDate(m.getStartDate())
                .endDate(m.getEndDate())
                .currentQuantity(m.getCurrentStock())
                .refillThreshold(m.getRefillThreshold())
                .notes(m.getInstructions())
                .isActive(m.isActive())
                .familyMemberId(m.getFamilyMember() != null ? m.getFamilyMember().getId() : null)
                .build();
    }
}
