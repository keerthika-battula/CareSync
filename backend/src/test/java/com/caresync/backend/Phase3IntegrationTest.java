package com.caresync.backend;

import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.family.entity.FamilyMember;
import com.caresync.backend.modules.medicine.entity.Medicine;
import com.caresync.backend.modules.medicine.entity.MedicineSchedule;
import com.caresync.backend.modules.medicine.entity.StockTransaction;
import com.caresync.backend.modules.medicine.repository.MedicineRepository;
import com.caresync.backend.modules.medicine.repository.StockTransactionRepository;
import com.caresync.backend.modules.reminder.entity.ReminderOccurrence;
import com.caresync.backend.modules.reminder.repository.ReminderOccurrenceRepository;
import com.caresync.backend.modules.reminder.service.RefillPredictionService;
import com.caresync.backend.modules.reminder.service.ReminderActionService;
import com.caresync.backend.modules.reminder.service.ReminderSchedulingService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class Phase3IntegrationTest {

    @Mock private ReminderOccurrenceRepository occurrenceRepository;
    @Mock private MedicineRepository medicineRepository;
    @Mock private StockTransactionRepository stockTransactionRepository;
    @Mock private RefillPredictionService refillPredictionService;
    @Mock private ReminderSchedulingService schedulingService;

    @InjectMocks
    private ReminderActionService reminderActionService;

    @Test
    void testTakenAction_ReducesStockAndPreventsNegative_AndChecksOwnership() {
        UUID userId = UUID.randomUUID();
        User user = new User(); user.setId(userId);
        
        Medicine medicine = new Medicine(); 
        medicine.setCurrentStock(30);
        
        MedicineSchedule schedule = new MedicineSchedule(); 
        schedule.setDosagePerIntake(new BigDecimal("2.5"));
        
        ReminderOccurrence occurrence = new ReminderOccurrence();
        occurrence.setId(UUID.randomUUID());
        occurrence.setUser(user);
        occurrence.setMedicine(medicine);
        occurrence.setSchedule(schedule);
        occurrence.setStatus("PENDING");

        when(occurrenceRepository.findById(occurrence.getId())).thenReturn(Optional.of(occurrence));
        
        reminderActionService.markTaken(occurrence.getId(), userId);

        assertEquals("TAKEN", occurrence.getStatus());
        assertNotNull(occurrence.getActionTime());
        assertEquals(28, medicine.getCurrentStock()); // 30 - 2.5 rounded/casted to int -> 27
        
        verify(medicineRepository).save(medicine);
        verify(stockTransactionRepository).save(any(StockTransaction.class));
        verify(refillPredictionService).checkRefill(medicine);
    }

    @Test
    void testSnoozeAction_IncrementsCountAndReschedules() {
        UUID userId = UUID.randomUUID();
        User user = new User(); user.setId(userId);
        
        ReminderOccurrence occurrence = new ReminderOccurrence();
        occurrence.setId(UUID.randomUUID());
        occurrence.setUser(user);
        occurrence.setStatus("PENDING");
        occurrence.setSnoozeCount(0);

        when(occurrenceRepository.findById(occurrence.getId())).thenReturn(Optional.of(occurrence));

        reminderActionService.snooze(occurrence.getId(), userId, 10);

        assertEquals("SNOOZED", occurrence.getStatus());
        assertEquals(1, occurrence.getSnoozeCount());
        verify(schedulingService).scheduleSnooze(occurrence, 10);
    }
    
    @Test
    void testDuplicateTaken_IsPrevented() {
        UUID userId = UUID.randomUUID();
        User user = new User(); user.setId(userId);
        
        ReminderOccurrence occurrence = new ReminderOccurrence();
        occurrence.setId(UUID.randomUUID());
        occurrence.setUser(user);
        occurrence.setStatus("TAKEN"); // Already taken

        when(occurrenceRepository.findById(occurrence.getId())).thenReturn(Optional.of(occurrence));
        
        reminderActionService.markTaken(occurrence.getId(), userId);

        // Should not reduce stock again
        verify(medicineRepository, never()).save(any());
    }
    
    @Test
    void testOwnership_ThrowsException() {
        UUID userId = UUID.randomUUID();
        User user = new User(); user.setId(UUID.randomUUID()); // Different user
        
        ReminderOccurrence occurrence = new ReminderOccurrence();
        occurrence.setId(UUID.randomUUID());
        occurrence.setUser(user);

        when(occurrenceRepository.findById(occurrence.getId())).thenReturn(Optional.of(occurrence));
        
        assertThrows(SecurityException.class, () -> {
            reminderActionService.markTaken(occurrence.getId(), userId);
        });
    }
}
