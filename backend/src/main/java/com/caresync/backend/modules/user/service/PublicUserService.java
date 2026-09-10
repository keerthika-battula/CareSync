package com.caresync.backend.modules.user.service;

import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.user.dto.PublicUserNameResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PublicUserService {

    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<PublicUserNameResponse> getPublicUserNames() {
        return userRepository.findAllByIsActiveTrue().stream()
                .map(u -> PublicUserNameResponse.builder()
                        .displayName((u.getFirstName() + " " + u.getLastName()).trim())
                        .build())
                .collect(Collectors.toList());
    }
}
