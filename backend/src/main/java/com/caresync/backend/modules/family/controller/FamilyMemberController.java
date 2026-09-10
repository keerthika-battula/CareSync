package com.caresync.backend.modules.family.controller;

import com.caresync.backend.common.response.ApiResponse;
import com.caresync.backend.modules.family.dto.FamilyMemberRequest;
import com.caresync.backend.modules.family.dto.FamilyMemberResponse;
import com.caresync.backend.modules.family.service.FamilyMemberService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/family")
@RequiredArgsConstructor
public class FamilyMemberController {

    private final FamilyMemberService familyMemberService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<FamilyMemberResponse>>> getFamilyMembers(Authentication auth) {
        List<FamilyMemberResponse> members = familyMemberService.getAllFamilyMembers(auth.getName());
        return ResponseEntity.ok(ApiResponse.success(members));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<FamilyMemberResponse>> addFamilyMember(
            Authentication auth, @Valid @RequestBody FamilyMemberRequest request) {
        FamilyMemberResponse member = familyMemberService.addFamilyMember(auth.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Family member added successfully", member));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteFamilyMember(
            Authentication auth, @PathVariable java.util.UUID id) {
        familyMemberService.deleteFamilyMember(auth.getName(), id);
        return ResponseEntity.ok(ApiResponse.success("Family member deleted successfully", null));
    }
}
