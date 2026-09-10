package com.caresync.backend.modules.user.controller;

import com.caresync.backend.common.response.ApiResponse;
import com.caresync.backend.common.response.PageResponse;
import com.caresync.backend.modules.user.dto.*;
import com.caresync.backend.modules.user.service.AdminUserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Admin User Management Controller.
 *
 * SCOPE & STATUS:
 * - Admin account management (list, view, create, role update, activation/deactivation) is fully implemented.
 * - Lazy healthcare overview (counts/summary) is implemented via GET /{userId}/healthcare-overview.
 * - Full admin access to individual healthcare records (medicines, documents, appointments, etc.)
 *   will be implemented in a dedicated later admin healthcare/data-access phase.
 * - Existing normal user ownership and IDOR enforcement remains strictly intact.
 */
@RestController
@RequestMapping("/api/v1/admin/users")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminUserController {

    private final AdminUserService adminUserService;

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<AdminUserResponse>>> getAllUsers(
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        PageResponse<AdminUserResponse> users = adminUserService.getAllUsers(pageable);
        return ResponseEntity.ok(ApiResponse.success(users));
    }

    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<AdminUserResponse>> getUserById(@PathVariable UUID userId) {
        AdminUserResponse user = adminUserService.getUserById(userId);
        return ResponseEntity.ok(ApiResponse.success(user));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AdminUserResponse>> createUser(
            @Valid @RequestBody AdminCreateUserRequest request) {
        AdminUserResponse createdUser = adminUserService.createUser(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("User created successfully", createdUser));
    }

    @PatchMapping("/{userId}/role")
    public ResponseEntity<ApiResponse<AdminUserResponse>> updateUserRole(
            @PathVariable UUID userId,
            @Valid @RequestBody UpdateUserRoleRequest request) {
        AdminUserResponse updatedUser = adminUserService.updateUserRole(userId, request.getRole());
        return ResponseEntity.ok(ApiResponse.success("User role updated successfully", updatedUser));
    }

    @PatchMapping("/{userId}/status")
    public ResponseEntity<ApiResponse<AdminUserResponse>> updateUserStatus(
            @PathVariable UUID userId,
            @Valid @RequestBody UpdateUserStatusRequest request) {
        AdminUserResponse updatedUser = adminUserService.updateUserStatus(userId, request.getIsActive());
        String msg = Boolean.TRUE.equals(request.getIsActive()) ? "User activated successfully" : "User deactivated successfully";
        return ResponseEntity.ok(ApiResponse.success(msg, updatedUser));
    }

    @GetMapping("/{userId}/healthcare-overview")
    public ResponseEntity<ApiResponse<AdminUserHealthcareOverviewResponse>> getUserHealthcareOverview(
            @PathVariable UUID userId) {
        AdminUserHealthcareOverviewResponse overview = adminUserService.getUserHealthcareOverview(userId);
        return ResponseEntity.ok(ApiResponse.success(overview));
    }

    @GetMapping("/{userId}/medicines")
    public ResponseEntity<ApiResponse<java.util.List<com.caresync.backend.modules.medicine.dto.MedicineResponse>>> getUserMedicines(
            @PathVariable UUID userId) {
        return ResponseEntity.ok(ApiResponse.success(adminUserService.getUserMedicines(userId)));
    }

    @GetMapping("/{userId}/documents")
    public ResponseEntity<ApiResponse<java.util.List<com.caresync.backend.modules.document.dto.DocumentResponse>>> getUserDocuments(
            @PathVariable UUID userId) {
        return ResponseEntity.ok(ApiResponse.success(adminUserService.getUserDocuments(userId)));
    }

    @GetMapping("/{userId}/documents/{documentId}/download")
    public ResponseEntity<org.springframework.core.io.Resource> downloadUserDocument(
            @PathVariable UUID userId,
            @PathVariable UUID documentId) throws Exception {
        com.caresync.backend.modules.document.service.DocumentService.DocumentDownload download =
                adminUserService.downloadUserDocument(userId, documentId);
        org.springframework.core.io.InputStreamResource resource =
                new org.springframework.core.io.InputStreamResource(download.getInputStream());
        String encodedFilename = java.net.URLEncoder.encode(download.getFileName(), java.nio.charset.StandardCharsets.UTF_8).replace("+", "%20");

        return ResponseEntity.ok()
                .header(org.springframework.http.HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + encodedFilename + "\"; filename*=UTF-8''" + encodedFilename)
                .contentType(org.springframework.http.MediaType.parseMediaType(download.getMimeType() != null ? download.getMimeType() : "application/octet-stream"))
                .body(resource);
    }

    @GetMapping("/{userId}/family")
    public ResponseEntity<ApiResponse<java.util.List<com.caresync.backend.modules.family.dto.FamilyMemberResponse>>> getUserFamilyMembers(
            @PathVariable UUID userId) {
        return ResponseEntity.ok(ApiResponse.success(adminUserService.getUserFamilyMembers(userId)));
    }

    @GetMapping("/{userId}/appointments")
    public ResponseEntity<ApiResponse<java.util.List<com.caresync.backend.modules.appointment.dto.AppointmentResponse>>> getUserAppointments(
            @PathVariable UUID userId) {
        return ResponseEntity.ok(ApiResponse.success(adminUserService.getUserAppointments(userId)));
    }
}
