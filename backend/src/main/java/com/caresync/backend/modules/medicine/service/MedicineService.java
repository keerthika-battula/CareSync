package com.caresync.backend.modules.medicine.service;

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
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MedicineService {

    private final MedicineRepository medicineRepository;
    private final MedicineScheduleRepository scheduleRepository;
    private final UserRepository userRepository;
    private final FamilyMemberRepository familyMemberRepository;

    @Transactional
    public MedicineResponse addMedicine(String email, MedicineRequest request) {
        User user = userRepository.findByEmail(email).orElseThrow();
        FamilyMember familyMember = familyMemberRepository.findById(request.getFamilyMemberId())
                .orElseThrow(() -> new IllegalArgumentException("Family member not found"));

        if (!familyMember.getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("Unauthorized");
        }

        Medicine medicine = Medicine.builder()
                .name(request.getName())
                .dosage(request.getDosage())
                .familyMember(familyMember)
                .startDate(request.getStartDate())
                .currentStock(request.getCurrentQuantity())
                .refillThreshold(request.getRefillThreshold())
                .build();

        Medicine savedMedicine = medicineRepository.save(medicine);
        return MedicineResponse.builder().id(savedMedicine.getId()).build();
    }

    @Transactional(readOnly = true)
    public List<MedicineResponse> getAllActiveMedicines(String email) {
        User user = userRepository.findByEmail(email).orElseThrow();
        List<Medicine> medicines = medicineRepository.findAll(); // Simplified for compile fix, normally filter by family members
        return new ArrayList<>(); // Stub
    }
}
