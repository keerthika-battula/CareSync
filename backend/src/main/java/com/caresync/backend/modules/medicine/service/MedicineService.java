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
import com.caresync.backend.modules.reminder.repository.ReminderOccurrenceRepository;
import com.caresync.backend.modules.reminder.service.ReminderActionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MedicineService {

    private final MedicineRepository medicineRepository;
    private final MedicineScheduleRepository scheduleRepository;
    private final ReminderOccurrenceRepository occurrenceRepository;
    private final ReminderActionService reminderActionService;
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
        saveSchedules(savedMedicine, request);

        // Generate today's doses for this user immediately
        reminderActionService.generateDosesForToday(user, LocalDate.now());

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
        saveSchedules(updated, request);

        // Remove old pending occurrences and regenerate for today
        occurrenceRepository.deleteAllByMedicineIdAndStatus(updated.getId(), "PENDING");
        reminderActionService.generateDosesForToday(user, LocalDate.now());

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

        occurrenceRepository.deleteAllByMedicineId(medicineId);
        scheduleRepository.deleteAllByMedicineId(medicineId);
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

    private void saveSchedules(Medicine medicine, MedicineRequest request) {
        String frequency = request.getFrequency() != null && !request.getFrequency().isBlank()
                ? request.getFrequency().trim()
                : "ONCE_DAILY";

        List<String> allTimes = new ArrayList<>();

        if (request.getSchedules() != null && !request.getSchedules().isEmpty()) {
            for (MedicineRequest.ScheduleRequest sr : request.getSchedules()) {
                if (sr.getScheduledTimes() != null && !sr.getScheduledTimes().isEmpty()) {
                    for (String t : sr.getScheduledTimes()) {
                        if (t != null && !t.isBlank()) {
                            allTimes.add(formatTimeString(t.trim()));
                        }
                    }
                } else if (sr.getScheduledTime() != null && !sr.getScheduledTime().isBlank()) {
                    allTimes.add(formatTimeString(sr.getScheduledTime().trim()));
                }
            }
        }

        if (allTimes.isEmpty()) {
            allTimes = getDefaultTimesForFrequency(frequency);
        }

        String scheduledTimesJson = "[" + allTimes.stream()
                .map(t -> "\"" + t + "\"")
                .collect(Collectors.joining(",")) + "]";

        List<MedicineSchedule> existingSchedules = scheduleRepository.findAllByMedicineId(medicine.getId());
        if (!existingSchedules.isEmpty()) {
            MedicineSchedule schedule = existingSchedules.get(0);
            schedule.setFrequency(frequency);
            schedule.setScheduledTimes(scheduledTimesJson);
            schedule.setDaysOfWeek("[1,2,3,4,5,6,7]");
            schedule.setActive(true);
            scheduleRepository.save(schedule);
        } else {
            MedicineSchedule schedule = MedicineSchedule.builder()
                    .medicine(medicine)
                    .frequency(frequency)
                    .scheduledTimes(scheduledTimesJson)
                    .daysOfWeek("[1,2,3,4,5,6,7]")
                    .dosagePerIntake(BigDecimal.ONE)
                    .isActive(true)
                    .build();
            scheduleRepository.save(schedule);
        }
    }

    private String formatTimeString(String raw) {
        if (raw == null || raw.isBlank()) return "08:00";
        try {
            return LocalTime.parse(raw).format(DateTimeFormatter.ofPattern("HH:mm"));
        } catch (Exception e) {
            return "08:00";
        }
    }

    private List<String> getDefaultTimesForFrequency(String frequency) {
        if (frequency == null) return List.of("08:00");
        return switch (frequency.toUpperCase()) {
            case "TWICE_DAILY" -> List.of("08:00", "20:00");
            case "THREE_TIMES_DAILY" -> List.of("08:00", "14:00", "20:00");
            case "FOUR_TIMES_DAILY" -> List.of("08:00", "12:00", "16:00", "20:00");
            case "AS_NEEDED" -> List.of("08:00");
            default -> List.of("08:00");
        };
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
        List<MedicineSchedule> schedules = scheduleRepository.findAllByMedicineId(m.getId());
        String frequency = "ONCE_DAILY";
        List<MedicineResponse.ScheduleResponse> scheduleResponses = new ArrayList<>();

        for (MedicineSchedule s : schedules) {
            frequency = s.getFrequency();
            List<LocalTime> times = parseScheduledTimes(s.getScheduledTimes());
            for (LocalTime t : times) {
                scheduleResponses.add(MedicineResponse.ScheduleResponse.builder()
                        .id(s.getId())
                        .frequency(s.getFrequency())
                        .scheduledTime(t)
                        .scheduledTimes(times)
                        .daysOfWeek(List.of(1, 2, 3, 4, 5, 6, 7))
                        .build());
            }
        }

        return MedicineResponse.builder()
                .id(m.getId())
                .name(m.getName())
                .dosage(m.getDosage())
                .frequency(frequency)
                .startDate(m.getStartDate())
                .endDate(m.getEndDate())
                .currentQuantity(m.getCurrentStock())
                .refillThreshold(m.getRefillThreshold())
                .notes(m.getInstructions())
                .isActive(m.isActive())
                .familyMemberId(m.getFamilyMember() != null ? m.getFamilyMember().getId() : null)
                .schedules(scheduleResponses)
                .build();
    }

    private List<LocalTime> parseScheduledTimes(String scheduledTimesJson) {
        List<LocalTime> list = new ArrayList<>();
        if (scheduledTimesJson == null || scheduledTimesJson.isBlank()) {
            return list;
        }

        String cleaned = scheduledTimesJson.replace("[", "").replace("]", "").replace("\"", "").trim();
        if (cleaned.isEmpty()) {
            return list;
        }

        String[] parts = cleaned.split(",");
        for (String part : parts) {
            String timeStr = part.trim();
            try {
                list.add(LocalTime.parse(timeStr));
            } catch (Exception ignored) {}
        }
        return list;
    }
}
