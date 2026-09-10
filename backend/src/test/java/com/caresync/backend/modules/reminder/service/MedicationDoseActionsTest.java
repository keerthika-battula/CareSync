package com.caresync.backend.modules.reminder.service;

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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MedicationDoseActionsTest {

    @Mock private ReminderOccurrenceRepository occurrenceRepository;
    @Mock private MedicineRepository medicineRepository;
    @Mock private MedicineScheduleRepository scheduleRepository;
    @Mock private StockTransactionRepository stockTransactionRepository;
    @Mock private RefillPredictionService refillPredictionService;
    @Mock private ReminderSchedulingService schedulingService;
    @Mock private UserRepository userRepository;

    @InjectMocks
    private ReminderActionService reminderActionService;

    private User user1;
    private User user2;
    private Medicine medicineA;
    private Medicine medicineB;
    private MedicineSchedule scheduleA;
    private ReminderOccurrence dose1;
    private ReminderOccurrence dose2;

    @BeforeEach
    void setUp() {
        user1 = new User();
        user1.setId(UUID.randomUUID());
        user1.setEmail("user1@caresync.test");

        user2 = new User();
        user2.setId(UUID.randomUUID());
        user2.setEmail("user2@caresync.test");

        medicineA = Medicine.builder()
                .name("Medicine A (e.g. Paracetamol)")
                .currentStock(30)
                .refillThreshold(7)
                .build();
        medicineA.setId(UUID.randomUUID());

        medicineB = Medicine.builder()
                .name("Medicine B (e.g. Amoxicillin)")
                .currentStock(20)
                .refillThreshold(5)
                .build();
        medicineB.setId(UUID.randomUUID());

        scheduleA = MedicineSchedule.builder()
                .medicine(medicineA)
                .dosagePerIntake(BigDecimal.ONE)
                .scheduledTimes("[\"08:00\"]")
                .isActive(true)
                .build();
        scheduleA.setId(UUID.randomUUID());

        dose1 = ReminderOccurrence.builder()
                .medicine(medicineA)
                .schedule(scheduleA)
                .user(user1)
                .scheduledTime(LocalDateTime.now().truncatedTo(ChronoUnit.HOURS))
                .originalScheduledTime(LocalDateTime.now().truncatedTo(ChronoUnit.HOURS))
                .status("PENDING")
                .snoozeCount(0)
                .build();
        dose1.setId(UUID.randomUUID());

        dose2 = ReminderOccurrence.builder()
                .medicine(medicineB)
                .user(user1)
                .scheduledTime(LocalDateTime.now().plusHours(4).truncatedTo(ChronoUnit.HOURS))
                .originalScheduledTime(LocalDateTime.now().plusHours(4).truncatedTo(ChronoUnit.HOURS))
                .status("PENDING")
                .snoozeCount(0)
                .build();
        dose2.setId(UUID.randomUUID());
    }

    @Test
    @DisplayName("1 & 2. Any medicine can have dose actions & Taken decreases stock")
    void testTakenAction_DecreasesStock() {
        when(occurrenceRepository.findById(dose1.getId())).thenReturn(Optional.of(dose1));
        when(occurrenceRepository.save(any(ReminderOccurrence.class))).thenAnswer(i -> i.getArguments()[0]);

        ReminderOccurrenceResponse response = reminderActionService.markTaken(dose1.getId(), user1.getId());

        assertEquals("TAKEN", response.getStatus());
        assertNotNull(response.getActionTime());
        assertEquals(29, medicineA.getCurrentStock());

        verify(medicineRepository).save(medicineA);
        verify(stockTransactionRepository).save(any(StockTransaction.class));
        verify(refillPredictionService).checkRefill(medicineA);
    }

    @Test
    @DisplayName("3. Skip does not decrease stock")
    void testSkipAction_DoesNotDecreaseStock() {
        when(occurrenceRepository.findById(dose1.getId())).thenReturn(Optional.of(dose1));
        when(occurrenceRepository.save(any(ReminderOccurrence.class))).thenAnswer(i -> i.getArguments()[0]);

        ReminderOccurrenceResponse response = reminderActionService.markSkipped(dose1.getId(), user1.getId());

        assertEquals("SKIPPED", response.getStatus());
        assertNotNull(response.getActionTime());
        assertEquals(30, medicineA.getCurrentStock());

        verify(medicineRepository, never()).save(any());
        verify(stockTransactionRepository, never()).save(any());
    }

    @Test
    @DisplayName("4, 6, 7. Snooze 15 minutes modifies the same dose and calculates new time without decreasing stock")
    void testSnooze15_ModifiesSameDoseWithoutDecreasingStock() {
        when(occurrenceRepository.findById(dose1.getId())).thenReturn(Optional.of(dose1));
        when(occurrenceRepository.save(any(ReminderOccurrence.class))).thenAnswer(i -> i.getArguments()[0]);

        LocalDateTime before = LocalDateTime.now();
        ReminderOccurrenceResponse response = reminderActionService.snooze(dose1.getId(), user1.getId(), 15);
        LocalDateTime after = LocalDateTime.now();

        assertEquals("SNOOZED", response.getStatus());
        assertEquals(1, response.getSnoozeCount());
        assertEquals(30, medicineA.getCurrentStock());

        assertNotNull(response.getSnoozedUntil());
        assertTrue(response.getSnoozedUntil().isAfter(before.plusMinutes(14)));
        assertTrue(response.getSnoozedUntil().isBefore(after.plusMinutes(16)));

        verify(schedulingService).scheduleSnooze(any(), eq(15));
        verify(medicineRepository, never()).save(any());
    }

    @Test
    @DisplayName("5 & 8. Snooze 30 minutes modifies the same dose and calculates new time without decreasing stock")
    void testSnooze30_CalculatesCorrectTimeWithoutDecreasingStock() {
        when(occurrenceRepository.findById(dose1.getId())).thenReturn(Optional.of(dose1));
        when(occurrenceRepository.save(any(ReminderOccurrence.class))).thenAnswer(i -> i.getArguments()[0]);

        LocalDateTime before = LocalDateTime.now();
        ReminderOccurrenceResponse response = reminderActionService.snooze(dose1.getId(), user1.getId(), 30);
        LocalDateTime after = LocalDateTime.now();

        assertEquals("SNOOZED", response.getStatus());
        assertEquals(1, response.getSnoozeCount());
        assertEquals(30, medicineA.getCurrentStock());

        assertTrue(response.getSnoozedUntil().isAfter(before.plusMinutes(29)));
        assertTrue(response.getSnoozedUntil().isBefore(after.plusMinutes(31)));
    }

    @Test
    @DisplayName("9 & 10. A snoozed dose can later be marked TAKEN and decreases stock exactly once")
    void testSnoozedDose_CanLaterBeMarkedTaken() {
        dose1.setStatus("SNOOZED");
        dose1.setSnoozeCount(1);
        dose1.setSnoozedUntil(LocalDateTime.now().plusMinutes(15));

        when(occurrenceRepository.findById(dose1.getId())).thenReturn(Optional.of(dose1));
        when(occurrenceRepository.save(any(ReminderOccurrence.class))).thenAnswer(i -> i.getArguments()[0]);

        ReminderOccurrenceResponse response = reminderActionService.markTaken(dose1.getId(), user1.getId());

        assertEquals("TAKEN", response.getStatus());
        assertEquals(29, medicineA.getCurrentStock());

        verify(medicineRepository, times(1)).save(medicineA);
        verify(stockTransactionRepository, times(1)).save(any());
    }

    @Test
    @DisplayName("11. Repeated Taken cannot decrement stock twice")
    void testRepeatedTaken_PreventsDoubleDecrement() {
        dose1.setStatus("TAKEN");
        when(occurrenceRepository.findById(dose1.getId())).thenReturn(Optional.of(dose1));

        ReminderOccurrenceResponse response = reminderActionService.markTaken(dose1.getId(), user1.getId());

        assertEquals("TAKEN", response.getStatus());
        assertEquals(30, medicineA.getCurrentStock());

        verify(medicineRepository, never()).save(any());
        verify(stockTransactionRepository, never()).save(any());
    }

    @Test
    @DisplayName("12 & 13. Multiple medicines and multiple doses of same medicine remain independent")
    void testMultipleMedicinesAndDoses_RemainIndependent() {
        when(occurrenceRepository.findById(dose1.getId())).thenReturn(Optional.of(dose1));
        when(occurrenceRepository.findById(dose2.getId())).thenReturn(Optional.of(dose2));
        when(occurrenceRepository.save(any(ReminderOccurrence.class))).thenAnswer(i -> i.getArguments()[0]);

        // Take dose1 (Medicine A)
        reminderActionService.markTaken(dose1.getId(), user1.getId());
        assertEquals(29, medicineA.getCurrentStock());
        assertEquals(20, medicineB.getCurrentStock()); // Medicine B untouched

        // Snooze dose2 (Medicine B)
        reminderActionService.snooze(dose2.getId(), user1.getId(), 15);
        assertEquals("TAKEN", dose1.getStatus());
        assertEquals("SNOOZED", dose2.getStatus());
        assertEquals(20, medicineB.getCurrentStock());
    }

    @Test
    @DisplayName("14. Unauthorized users cannot snooze another user's dose")
    void testUnauthorizedUser_CannotSnooze() {
        when(occurrenceRepository.findById(dose1.getId())).thenReturn(Optional.of(dose1));

        assertThrows(SecurityException.class, () ->
                reminderActionService.snooze(dose1.getId(), user2.getId(), 15));
    }

    @Test
    @DisplayName("15. Unauthorized users cannot mark another user's dose Taken")
    void testUnauthorizedUser_CannotMarkTaken() {
        when(occurrenceRepository.findById(dose1.getId())).thenReturn(Optional.of(dose1));

        assertThrows(SecurityException.class, () ->
                reminderActionService.markTaken(dose1.getId(), user2.getId()));
    }

    @Test
    @DisplayName("16. Unauthorized users cannot skip another user's dose")
    void testUnauthorizedUser_CannotSkip() {
        when(occurrenceRepository.findById(dose1.getId())).thenReturn(Optional.of(dose1));

        assertThrows(SecurityException.class, () ->
                reminderActionService.markSkipped(dose1.getId(), user2.getId()));
    }

    @Test
    @DisplayName("17. Stock never becomes negative")
    void testStock_NeverBecomesNegative() {
        medicineA.setCurrentStock(0); // 0 stock left

        when(occurrenceRepository.findById(dose1.getId())).thenReturn(Optional.of(dose1));
        when(occurrenceRepository.save(any(ReminderOccurrence.class))).thenAnswer(i -> i.getArguments()[0]);

        reminderActionService.markTaken(dose1.getId(), user1.getId());

        assertEquals(0, medicineA.getCurrentStock());
        verify(medicineRepository).save(medicineA);
    }
}
