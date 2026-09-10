package com.caresync.backend.modules.user.controller;

import com.caresync.backend.common.response.ApiResponse;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.user.dto.AdminUserResponse;
import com.caresync.backend.modules.user.dto.PublicUserNameResponse;
import com.caresync.backend.modules.user.service.PublicUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
}
