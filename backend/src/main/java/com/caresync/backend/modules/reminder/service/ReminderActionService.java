package com.caresync.backend.modules.reminder.service;

import com.caresync.backend.common.exception.ForbiddenException;
import com.caresync.backend.common.exception.ResourceNotFoundException;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.medicine.entity.Medicine;
import com.caresync.backend.modules.medicine.entity.MedicineSchedule;
import com.caresync.backend.modules.medicine.entity.StockTransaction;
import com.caresync.backend.modules.medicine.repository.MedicineRepository;
import com.caresync.backend.modules.medicine.repository.MedicineScheduleRepository;
import com.caresync.backend.modules.medicine.repository.StockTransactionRepository;
import com.caresync.backend.modules.reminder.dto.ReminderOccurrenceResponse;
import com.caresync.backend.modules.reminder.entity.ReminderOccurrence;
import com.caresync.backend.modules.reminder.repository.ReminderOccurrenceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ReminderActionService {

    private final ReminderOccurrenceRepository occurrenceRepository;
    private final MedicineRepository medicineRepository;
    private final MedicineScheduleRepository scheduleRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final RefillPredictionService refillPredictionService;
    private final ReminderSchedulingService schedulingService;
    private final UserRepository userRepository;

    @Transactional
    public ReminderOccurrenceResponse markTaken(UUID occurrenceId, UUID userId) {
        ReminderOccurrence occurrence = occurrenceRepository.findById(occurrenceId)
                .orElseThrow(() -> new ResourceNotFoundException("Reminder occurrence not found"));
        if (!occurrence.getUser().getId().equals(userId)) {
            throw new SecurityException("Unauthorized");
        }
        if (!"PENDING".equals(occurrence.getStatus()) && !"SNOOZED".equals(occurrence.getStatus())) {
            // Already taken or skipped - idempotent return
            return mapToResponse(occurrence);
        }

        occurrence.setStatus("TAKEN");
        occurrence.setActionTime(LocalDateTime.now());
        ReminderOccurrence saved = occurrenceRepository.save(occurrence);
        ReminderOccurrence toMap = saved != null ? saved : occurrence;

        Medicine medicine = occurrence.getMedicine();
        if (medicine != null && medicine.getCurrentStock() != null) {
            BigDecimal dose = (occurrence.getSchedule() != null && occurrence.getSchedule().getDosagePerIntake() != null)
                    ? occurrence.getSchedule().getDosagePerIntake()
                    : BigDecimal.ONE;

            int dosageQuantity = dose.intValue();
            if (dosageQuantity <= 0) {
                dosageQuantity = 1;
            }

            int current = medicine.getCurrentStock() != null ? medicine.getCurrentStock() : 0;
            int newStock = Math.max(0, current - dosageQuantity);
            medicine.setCurrentStock(newStock);
            medicineRepository.save(medicine);

            stockTransactionRepository.save(StockTransaction.builder()
                    .medicine(medicine)
                    .quantityChange(BigDecimal.valueOf(dosageQuantity).negate())
                    .transactionType("TAKEN")
                    .referenceId(occurrence.getId())
                    .build());

            refillPredictionService.checkRefill(medicine);
        }

        return mapToResponse(toMap);
    }

    @Transactional
    public ReminderOccurrenceResponse markSkipped(UUID occurrenceId, UUID userId) {
        ReminderOccurrence occurrence = occurrenceRepository.findById(occurrenceId)
                .orElseThrow(() -> new ResourceNotFoundException("Reminder occurrence not found"));
        if (!occurrence.getUser().getId().equals(userId)) {
            throw new SecurityException("Unauthorized");
        }

        if (!"PENDING".equals(occurrence.getStatus()) && !"SNOOZED".equals(occurrence.getStatus())) {
            return mapToResponse(occurrence);
        }

        occurrence.setStatus("SKIPPED");
        occurrence.setActionTime(LocalDateTime.now());
        ReminderOccurrence saved = occurrenceRepository.save(occurrence);
        ReminderOccurrence toMap = saved != null ? saved : occurrence;
        return mapToResponse(toMap);
    }

    @Transactional
    public ReminderOccurrenceResponse snooze(UUID occurrenceId, UUID userId, int minutes) {
        ReminderOccurrence occurrence = occurrenceRepository.findById(occurrenceId)
                .orElseThrow(() -> new ResourceNotFoundException("Reminder occurrence not found"));
        if (!occurrence.getUser().getId().equals(userId)) {
            throw new SecurityException("Unauthorized");
        }

        if (occurrence.getOriginalScheduledTime() == null) {
            occurrence.setOriginalScheduledTime(occurrence.getScheduledTime());
        }

        LocalDateTime newTime = LocalDateTime.now().plusMinutes(minutes);
        occurrence.setStatus("SNOOZED");
        occurrence.setSnoozedUntil(newTime);
        occurrence.setScheduledTime(newTime);
        occurrence.setSnoozeCount((occurrence.getSnoozeCount() != null ? occurrence.getSnoozeCount() : 0) + 1);
        occurrence.setActionTime(LocalDateTime.now());

        ReminderOccurrence saved = occurrenceRepository.save(occurrence);
        ReminderOccurrence toMap = saved != null ? saved : occurrence;

        // Reschedule Quartz reminder trigger if scheduler is active
        schedulingService.scheduleSnooze(toMap, minutes);

        return mapToResponse(toMap);
    }


    @Transactional
    public List<ReminderOccurrenceResponse> getTodayDosesForUser(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return getTodayDoses(user.getId());
    }

    @Transactional
    public List<ReminderOccurrenceResponse> getTodayDoses(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        LocalDate today = LocalDate.now();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.atTime(LocalTime.MAX);

        // Ensure doses are generated for today for all active medicines
        generateDosesForToday(user, today);

        List<ReminderOccurrence> occurrences = occurrenceRepository
                .findAllByUserIdAndScheduledTimeBetweenOrderByScheduledTimeAsc(user.getId(), startOfDay, endOfDay);

        return occurrences.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    @Transactional
    public void generateDosesForToday(User user, LocalDate date) {
        List<Medicine> medicines = medicineRepository.findAllByFamilyMemberUserIdAndIsActiveTrue(user.getId());
        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.atTime(LocalTime.MAX);

        for (Medicine medicine : medicines) {
            if (medicine.getStartDate() != null && medicine.getStartDate().isAfter(date)) {
                continue;
            }
            if (medicine.getEndDate() != null && medicine.getEndDate().isBefore(date)) {
                continue;
            }

            List<MedicineSchedule> schedules = scheduleRepository.findAllByMedicineId(medicine.getId());
            if (schedules.isEmpty()) {
                // Default fallback dose at 08:00 if no explicit schedules exist
                LocalDateTime scheduledTime = date.atTime(8, 0);
                boolean exists = occurrenceRepository.existsByMedicineIdAndScheduledTime(medicine.getId(), scheduledTime);
                if (!exists) {
                    ReminderOccurrence occ = ReminderOccurrence.builder()
                            .medicine(medicine)
                            .user(user)
                            .scheduledTime(scheduledTime)
                            .originalScheduledTime(scheduledTime)
                            .status("PENDING")
                            .snoozeCount(0)
                            .build();
                    occurrenceRepository.save(occ);
                }
            } else {
                for (MedicineSchedule schedule : schedules) {
                    if (!schedule.isActive()) continue;

                    List<LocalTime> times = parseScheduledTimes(schedule.getScheduledTimes());
                    for (LocalTime time : times) {
                        LocalDateTime scheduledTime = date.atTime(time);
                        boolean exists = occurrenceRepository.existsByMedicineIdAndScheduledTime(medicine.getId(), scheduledTime);
                        if (!exists) {
                            ReminderOccurrence occ = ReminderOccurrence.builder()
                                    .medicine(medicine)
                                    .schedule(schedule)
                                    .user(user)
                                    .scheduledTime(scheduledTime)
                                    .originalScheduledTime(scheduledTime)
                                    .status("PENDING")
                                    .snoozeCount(0)
                                    .build();
                            occurrenceRepository.save(occ);
                        }
                    }
                }
            }
        }
    }

    private List<LocalTime> parseScheduledTimes(String scheduledTimesJson) {
        List<LocalTime> list = new ArrayList<>();
        if (scheduledTimesJson == null || scheduledTimesJson.isBlank()) {
            list.add(LocalTime.of(8, 0));
            return list;
        }

        String cleaned = scheduledTimesJson.replace("[", "").replace("]", "").replace("\"", "").trim();
        if (cleaned.isEmpty()) {
            list.add(LocalTime.of(8, 0));
            return list;
        }

        String[] parts = cleaned.split(",");
        for (String part : parts) {
            String timeStr = part.trim();
            try {
                if (timeStr.length() == 5) { // "08:00"
                    list.add(LocalTime.parse(timeStr));
                } else if (timeStr.length() == 8) { // "08:00:00"
                    list.add(LocalTime.parse(timeStr));
                } else {
                    list.add(LocalTime.of(8, 0));
                }
            } catch (Exception e) {
                list.add(LocalTime.of(8, 0));
            }
        }
        return list.isEmpty() ? List.of(LocalTime.of(8, 0)) : list;
    }

    public ReminderOccurrenceResponse mapToResponse(ReminderOccurrence occ) {
        Medicine m = occ.getMedicine();
        BigDecimal dosageQty = (occ.getSchedule() != null && occ.getSchedule().getDosagePerIntake() != null)
                ? occ.getSchedule().getDosagePerIntake()
                : BigDecimal.ONE;

        return ReminderOccurrenceResponse.builder()
                .id(occ.getId())
                .medicineId(m != null ? m.getId() : null)
                .medicineName(m != null ? m.getName() : "Unknown Medicine")
                .dosage(m != null ? m.getDosage() : null)
                .dosagePerIntake(dosageQty)
                .dosageUnit(m != null ? m.getDosageUnit() : null)
                .currentStock(m != null ? m.getCurrentStock() : null)
                .refillThreshold(m != null ? m.getRefillThreshold() : null)
                .scheduledTime(occ.getScheduledTime())
                .originalScheduledTime(occ.getOriginalScheduledTime() != null ? occ.getOriginalScheduledTime() : occ.getScheduledTime())
                .snoozedUntil(occ.getSnoozedUntil())
                .status(occ.getStatus())
                .actionTime(occ.getActionTime())
                .snoozeCount(occ.getSnoozeCount() != null ? occ.getSnoozeCount() : 0)
                .build();
    }
}
