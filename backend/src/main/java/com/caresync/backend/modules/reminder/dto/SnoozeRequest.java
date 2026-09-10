package com.caresync.backend.modules.reminder.dto;

import jakarta.validation.constraints.Min;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SnoozeRequest {
    @Min(value = 1, message = "Snooze minutes must be at least 1")
    private int minutes;
}
