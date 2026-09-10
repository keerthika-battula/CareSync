package com.caresync.backend.modules.reminder.service;

import com.caresync.backend.modules.medicine.entity.Medicine;
import com.caresync.backend.modules.medicine.entity.StockTransaction;
import com.caresync.backend.modules.medicine.repository.MedicineRepository;
import com.caresync.backend.modules.medicine.repository.StockTransactionRepository;
import com.caresync.backend.modules.reminder.entity.ReminderOccurrence;
import com.caresync.backend.modules.reminder.repository.ReminderOccurrenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ReminderActionService {

    private final ReminderOccurrenceRepository occurrenceRepository;
    private final MedicineRepository medicineRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final RefillPredictionService refillPredictionService;
    private final ReminderSchedulingService schedulingService;

    @Transactional
    public void markTaken(UUID occurrenceId, UUID userId) {
        ReminderOccurrence occurrence = occurrenceRepository.findById(occurrenceId).orElseThrow();
        if (!occurrence.getUser().getId().equals(userId)) throw new SecurityException("Unauthorized");
        if (!"PENDING".equals(occurrence.getStatus()) && !"SNOOZED".equals(occurrence.getStatus())) {
            return; // prevent double logging
        }

        occurrence.setStatus("TAKEN");
        occurrence.setActionTime(LocalDateTime.now());
        occurrenceRepository.save(occurrence);

        Medicine medicine = occurrence.getMedicine();
        if (medicine.getCurrentStock() != null && occurrence.getSchedule() != null) {
            BigDecimal dose = occurrence.getSchedule().getDosagePerIntake();
            medicine.setCurrentStock(Math.max(0, medicine.getCurrentStock() - dose.intValue()));
            medicineRepository.save(medicine);

            stockTransactionRepository.save(StockTransaction.builder()
                    .medicine(medicine)
                    .quantityChange(dose.negate())
                    .transactionType("TAKEN")
                    .referenceId(occurrence.getId())
                    .build());
            
            refillPredictionService.checkRefill(medicine);
        }
    }

    @Transactional
    public void markSkipped(UUID occurrenceId, UUID userId) {
        ReminderOccurrence occurrence = occurrenceRepository.findById(occurrenceId).orElseThrow();
        if (!occurrence.getUser().getId().equals(userId)) throw new SecurityException("Unauthorized");

        occurrence.setStatus("SKIPPED");
        occurrence.setActionTime(LocalDateTime.now());
        occurrenceRepository.save(occurrence);
    }

    @Transactional
    public void snooze(UUID occurrenceId, UUID userId, int minutes) {
        ReminderOccurrence occurrence = occurrenceRepository.findById(occurrenceId).orElseThrow();
        if (!occurrence.getUser().getId().equals(userId)) throw new SecurityException("Unauthorized");

        occurrence.setStatus("SNOOZED");
        occurrence.setSnoozeCount(occurrence.getSnoozeCount() + 1);
        occurrence.setActionTime(LocalDateTime.now());
        occurrenceRepository.save(occurrence);

        // Schedule new Quartz job for the snoozed time
        schedulingService.scheduleSnooze(occurrence, minutes);
    }
}
