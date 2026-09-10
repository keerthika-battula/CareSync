package com.caresync.backend.modules.reminder.controller;

import com.caresync.backend.common.exception.ResourceNotFoundException;
import com.caresync.backend.common.response.ApiResponse;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.reminder.dto.ReminderOccurrenceResponse;
import com.caresync.backend.modules.reminder.dto.SnoozeRequest;
import com.caresync.backend.modules.reminder.service.ReminderActionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/reminders")
@RequiredArgsConstructor
public class ReminderController {

    private final ReminderActionService reminderActionService;
    private final UserRepository userRepository;

    @GetMapping("/today")
    public ResponseEntity<ApiResponse<List<ReminderOccurrenceResponse>>> getTodayDoses(Authentication auth) {
        User user = userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        List<ReminderOccurrenceResponse> doses = reminderActionService.getTodayDoses(user.getId());
        return ResponseEntity.ok(ApiResponse.success(doses));
    }

    @PostMapping("/{id}/taken")
    public ResponseEntity<ApiResponse<ReminderOccurrenceResponse>> markTaken(
            Authentication auth, @PathVariable UUID id) {
        User user = userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        ReminderOccurrenceResponse response = reminderActionService.markTaken(id, user.getId());
        return ResponseEntity.ok(ApiResponse.success("Marked as taken", response));
    }

    @PostMapping("/{id}/skip")
    public ResponseEntity<ApiResponse<ReminderOccurrenceResponse>> markSkipped(
            Authentication auth, @PathVariable UUID id) {
        User user = userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        ReminderOccurrenceResponse response = reminderActionService.markSkipped(id, user.getId());
        return ResponseEntity.ok(ApiResponse.success("Marked as skipped", response));
    }

    @PostMapping("/{id}/snooze")
    public ResponseEntity<ApiResponse<ReminderOccurrenceResponse>> snooze(
            Authentication auth, @PathVariable UUID id, @Valid @RequestBody SnoozeRequest request) {
        User user = userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        ReminderOccurrenceResponse response = reminderActionService.snooze(id, user.getId(), request.getMinutes());
        return ResponseEntity.ok(ApiResponse.success("Reminder snoozed", response));
    }
}
