package com.caresync.backend.modules.medicine.controller;

import com.caresync.backend.common.response.ApiResponse;
import com.caresync.backend.modules.medicine.dto.MedicineRequest;
import com.caresync.backend.modules.medicine.dto.MedicineResponse;
import com.caresync.backend.modules.medicine.service.MedicineService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/medicines")
@RequiredArgsConstructor
public class MedicineController {

    private final MedicineService medicineService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<MedicineResponse>>> getMedicines(Authentication auth) {
        List<MedicineResponse> medicines = medicineService.getAllActiveMedicines(auth.getName());
        return ResponseEntity.ok(ApiResponse.success(medicines));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<MedicineResponse>> addMedicine(
            Authentication auth, @Valid @RequestBody MedicineRequest request) {
        MedicineResponse medicine = medicineService.addMedicine(auth.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Medicine added successfully", medicine));
    }
}
