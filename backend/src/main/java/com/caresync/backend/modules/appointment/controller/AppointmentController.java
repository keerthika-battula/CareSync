package com.caresync.backend.modules.appointment.controller;

import com.caresync.backend.common.response.ApiResponse;
import com.caresync.backend.modules.appointment.dto.AppointmentRequest;
import com.caresync.backend.modules.appointment.dto.AppointmentResponse;
import com.caresync.backend.modules.appointment.service.AppointmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/appointments")
@RequiredArgsConstructor
public class AppointmentController {

    private final AppointmentService appointmentService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<AppointmentResponse>>> getUpcomingAppointments(Authentication auth) {
        List<AppointmentResponse> appointments = appointmentService.getUpcoming(auth.getName());
        return ResponseEntity.ok(ApiResponse.success(appointments));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AppointmentResponse>> createAppointment(
            Authentication auth, @Valid @RequestBody AppointmentRequest request) {
        AppointmentResponse created = appointmentService.createAppointment(auth.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Appointment scheduled successfully", created));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteAppointment(
            Authentication auth, @PathVariable UUID id) {
        appointmentService.deleteAppointment(auth.getName(), id);
        return ResponseEntity.ok(ApiResponse.success("Appointment deleted successfully", null));
    }
}
