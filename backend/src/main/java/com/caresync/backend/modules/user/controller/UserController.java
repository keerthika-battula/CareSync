package com.caresync.backend.modules.user.controller;

import com.caresync.backend.common.response.ApiResponse;
import com.caresync.backend.modules.auth.dto.ChangePasswordRequest;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.user.dto.AdminUserResponse;
import com.caresync.backend.modules.user.dto.PublicUserNameResponse;
import com.caresync.backend.modules.user.service.PublicUserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final PublicUserService publicUserService;

    @GetMapping("/names")
    public ResponseEntity<ApiResponse<List<PublicUserNameResponse>>> getPublicUserNames() {
        List<PublicUserNameResponse> names = publicUserService.getPublicUserNames();
        return ResponseEntity.ok(ApiResponse.success(names));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<AdminUserResponse>> getCurrentUser(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(ApiResponse.success(AdminUserResponse.fromEntity(user)));
    }

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody ChangePasswordRequest request) {
        publicUserService.changePassword(user, request);
        return ResponseEntity.ok(ApiResponse.success("Password updated successfully", null));
    }
}
