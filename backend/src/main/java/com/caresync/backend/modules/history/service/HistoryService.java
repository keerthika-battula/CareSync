package com.caresync.backend.modules.history.service;

import com.caresync.backend.modules.reminder.entity.ReminderOccurrence;
import com.caresync.backend.modules.reminder.repository.ReminderOccurrenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class HistoryService {

    private final ReminderOccurrenceRepository occurrenceRepository;

    @Transactional(readOnly = true)
    public List<String> getUserHistory(UUID userId) {
        // Simple aggregate for Phase 4, usually returns HistoryDTOs
        List<ReminderOccurrence> occurrences = occurrenceRepository.findAllByUserIdAndScheduledTimeBetween(
                userId, LocalDateTime.now().minusDays(30), LocalDateTime.now());
        
        return occurrences.stream()
                .filter(o -> !"PENDING".equals(o.getStatus()))
                .map(o -> o.getMedicine().getName() + " was " + o.getStatus() + " at " + o.getActionTime())
                .collect(Collectors.toList());
    }
}
