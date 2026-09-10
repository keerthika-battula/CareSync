package com.caresync.backend.modules.family.service;

import com.caresync.backend.common.exception.ResourceNotFoundException;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.family.dto.FamilyMemberRequest;
import com.caresync.backend.modules.family.dto.FamilyMemberResponse;
import com.caresync.backend.modules.family.entity.FamilyMember;
import com.caresync.backend.modules.family.repository.FamilyMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FamilyMemberService {

    private final FamilyMemberRepository familyMemberRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<FamilyMemberResponse> getAllFamilyMembers(String email) {
        User user = userRepository.findByEmail(email).orElseThrow();
        return familyMemberRepository.findAllByUserId(user.getId()).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public FamilyMemberResponse addFamilyMember(String email, FamilyMemberRequest request) {
        User user = userRepository.findByEmail(email).orElseThrow();
        
        FamilyMember member = FamilyMember.builder()
                .name(request.getName())
                .relationship(request.getRelationship())
                .dateOfBirth(request.getDateOfBirth())
                .user(user)
                .build();
                
        FamilyMember saved = familyMemberRepository.save(member);
        return mapToResponse(saved);
    }

    private FamilyMemberResponse mapToResponse(FamilyMember member) {
        return FamilyMemberResponse.builder()
                .id(member.getId())
                .name(member.getName())
                .relationship(member.getRelationship())
                .dateOfBirth(member.getDateOfBirth())
                .build();
    }
}
