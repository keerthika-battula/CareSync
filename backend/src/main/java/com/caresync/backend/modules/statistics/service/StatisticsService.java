package com.caresync.backend.modules.statistics.service;

import com.caresync.backend.modules.appointment.repository.AppointmentRepository;
import com.caresync.backend.modules.document.repository.DocumentRepository;
import com.caresync.backend.modules.medicine.repository.MedicineRepository;
import com.caresync.backend.modules.reminder.repository.ReminderOccurrenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class StatisticsService {

    private final AppointmentRepository appointmentRepository;
    private final DocumentRepository documentRepository;
    private final MedicineRepository medicineRepository;
    private final ReminderOccurrenceRepository occurrenceRepository;

    @Transactional(readOnly = true)
    public Map<String, Object> getDashboardStats(UUID userId) {
        Map<String, Object> stats = new HashMap<>();

        long upcomingAppointments = appointmentRepository.findAllByFamilyMemberUserIdAndAppointmentDateGreaterThanEqualAndStatus(userId, LocalDate.now(), "UPCOMING").size();
        long totalDocs = documentRepository.findAllByFamilyMemberUserId(userId).size();
        long activeMedicines = medicineRepository.findAllByFamilyMemberUserIdAndIsActiveTrue(userId).size();

        stats.put("upcomingAppointments", upcomingAppointments);
        stats.put("totalDocuments", totalDocs);
        stats.put("activeMedicines", activeMedicines);

        // Calculate simple adherence based on TAKEN vs PENDING/SKIPPED could be added here
        return stats;
    }
}
