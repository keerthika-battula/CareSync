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

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MedicineResponse>> getMedicineById(
            Authentication auth, @PathVariable java.util.UUID id) {
        MedicineResponse medicine = medicineService.getMedicineById(auth.getName(), id);
        return ResponseEntity.ok(ApiResponse.success(medicine));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<MedicineResponse>> addMedicine(
            Authentication auth, @Valid @RequestBody MedicineRequest request) {
        MedicineResponse medicine = medicineService.addMedicine(auth.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Medicine added successfully", medicine));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<MedicineResponse>> updateMedicine(
            Authentication auth, @PathVariable java.util.UUID id, @Valid @RequestBody MedicineRequest request) {
        MedicineResponse medicine = medicineService.updateMedicine(auth.getName(), id, request);
        return ResponseEntity.ok(ApiResponse.success("Medicine updated successfully", medicine));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteMedicine(
            Authentication auth, @PathVariable java.util.UUID id) {
        medicineService.deleteMedicine(auth.getName(), id);
        return ResponseEntity.ok(ApiResponse.success("Medicine deleted successfully", null));
    }
}
