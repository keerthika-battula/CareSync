package com.caresync.backend.modules.reminder.repository;

import com.caresync.backend.modules.reminder.entity.ReminderOccurrence;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;
import java.time.LocalDateTime;

public interface ReminderOccurrenceRepository extends JpaRepository<ReminderOccurrence, UUID> {
    List<ReminderOccurrence> findAllByUserIdAndScheduledTimeBetween(UUID userId, LocalDateTime start, LocalDateTime end);
    List<ReminderOccurrence> findAllByUserIdAndScheduledTimeBetweenOrderByScheduledTimeAsc(UUID userId, LocalDateTime start, LocalDateTime end);
    List<ReminderOccurrence> findAllByMedicineIdOrderByScheduledTimeDesc(UUID medicineId);
    boolean existsByMedicineIdAndScheduledTime(UUID medicineId, LocalDateTime scheduledTime);
    void deleteAllByMedicineIdAndStatus(UUID medicineId, String status);
    void deleteAllByMedicineId(UUID medicineId);
}
