package com.caresync.backend.modules.user.service;

import com.caresync.backend.common.exception.BadRequestException;
import com.caresync.backend.modules.auth.dto.ChangePasswordRequest;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.user.dto.PublicUserNameResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PublicUserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<PublicUserNameResponse> getPublicUserNames() {
        return userRepository.findAllByIsActiveTrue().stream()
                .map(u -> PublicUserNameResponse.builder()
                        .displayName((u.getFirstName() + " " + u.getLastName()).trim())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional
    public void changePassword(User user, ChangePasswordRequest request) {
        if (user == null) {
            throw new BadRequestException("User must be authenticated to update password.");
        }

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new BadRequestException("Current password is incorrect.");
        }

        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("New password and confirm password do not match.");
        }

        if (passwordEncoder.matches(request.getNewPassword(), user.getPasswordHash())) {
            throw new BadRequestException("New password cannot be the same as the current password.");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }
}
