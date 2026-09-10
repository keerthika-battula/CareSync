package com.caresync.backend.modules.auth.service;

import com.caresync.backend.common.exception.BadRequestException;
import com.caresync.backend.common.exception.ConflictException;
import com.caresync.backend.modules.auth.dto.*;
import com.caresync.backend.modules.auth.entity.PasswordResetToken;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.repository.PasswordResetTokenRepository;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.security.JwtService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final EmailService emailService;

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    @Value("${caresync.auth.password-reset.cooldown-seconds:60}")
    private int resendCooldownSeconds;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ConflictException("Email is already registered");
        }

        User user = User.builder()
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .isActive(true)
                .isEmailVerified(false)
                .build();

        User savedUser = userRepository.save(user);
        
        String jwtToken = jwtService.generateAccessToken(savedUser);
        String refreshToken = jwtService.generateRefreshToken(savedUser.getEmail());

        return buildAuthResponse(savedUser, jwtToken, refreshToken);
    }

    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow();

        String jwtToken = jwtService.generateAccessToken(user);
        String refreshToken = jwtService.generateRefreshToken(user.getEmail());

        return buildAuthResponse(user, jwtToken, refreshToken);
    }

    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) {
        String email = request.getEmail() != null ? request.getEmail().trim() : "";
        Optional<User> userOpt = userRepository.findByEmailIgnoreCase(email);

        // Security requirement: generic response to prevent account enumeration
        if (userOpt.isEmpty()) {
            log.debug("Password reset requested for non-existent email: {}", email);
            return;
        }

        User user = userOpt.get();

        // Check resend cooldown
        if (resendCooldownSeconds > 0) {
            Optional<PasswordResetToken> lastTokenOpt = passwordResetTokenRepository.findFirstByUserOrderByCreatedAtDesc(user);
            if (lastTokenOpt.isPresent() && lastTokenOpt.get().getCreatedAt() != null) {
                long secondsSinceLast = Duration.between(lastTokenOpt.get().getCreatedAt(), LocalDateTime.now()).getSeconds();
                if (secondsSinceLast < resendCooldownSeconds) {
                    throw new BadRequestException("A password reset code was recently requested. Please wait before requesting a new code.");
                }
            }
        }

        // Invalidate previous active reset tokens for this user
        List<PasswordResetToken> activeTokens = passwordResetTokenRepository.findAllByUserAndUsedAtIsNull(user);
        for (PasswordResetToken token : activeTokens) {
            token.setUsedAt(LocalDateTime.now());
        }
        passwordResetTokenRepository.saveAll(activeTokens);

        // Generate cryptographically secure 6-digit OTP (100000..999999)
        int codeInt = 100000 + SECURE_RANDOM.nextInt(900000);
        String otpCode = String.valueOf(codeInt);

        // Save hashed OTP with 15-minute expiration
        PasswordResetToken resetToken = PasswordResetToken.builder()
                .user(user)
                .email(user.getEmail())
                .codeHash(passwordEncoder.encode(otpCode))
                .expiresAt(LocalDateTime.now().plusMinutes(15))
                .attemptCount(0)
                .build();
        passwordResetTokenRepository.save(resetToken);

        // Dispatch email through configured mail service
        emailService.sendPasswordResetEmail(user.getEmail(), otpCode);
    }

    @Transactional(noRollbackFor = BadRequestException.class)
    public void resetPassword(ResetPasswordRequest request) {
        String email = request.getEmail() != null ? request.getEmail().trim() : "";
        User user = userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new BadRequestException("Invalid or expired verification code"));

        PasswordResetToken token = passwordResetTokenRepository.findFirstByUserAndUsedAtIsNullOrderByCreatedAtDesc(user)
                .orElseThrow(() -> new BadRequestException("Invalid or expired verification code"));

        if (token.isExpired()) {
            token.setUsedAt(LocalDateTime.now());
            passwordResetTokenRepository.saveAndFlush(token);
            throw new BadRequestException("Invalid or expired verification code");
        }

        if (token.getAttemptCount() >= 5) {
            token.setUsedAt(LocalDateTime.now());
            passwordResetTokenRepository.saveAndFlush(token);
            throw new BadRequestException("Too many failed attempts. Please request a new verification code.");
        }

        String inputCode = request.getCode() != null ? request.getCode().trim() : "";
        if (!passwordEncoder.matches(inputCode, token.getCodeHash())) {
            token.setAttemptCount(token.getAttemptCount() + 1);
            if (token.getAttemptCount() >= 5) {
                token.setUsedAt(LocalDateTime.now());
            }
            passwordResetTokenRepository.saveAndFlush(token);
            throw new BadRequestException("Invalid or expired verification code");
        }

        // OTP verified: update user password with BCrypt hash
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        // Invalidate token to prevent reuse
        token.setUsedAt(LocalDateTime.now());
        passwordResetTokenRepository.save(token);
    }

    private AuthResponse buildAuthResponse(User user, String jwtToken, String refreshToken) {
        return AuthResponse.builder()
                .accessToken(jwtToken)
                .refreshToken(refreshToken)
                .user(AuthResponse.UserDto.builder()
                        .id(user.getId())
                        .email(user.getEmail())
                        .firstName(user.getFirstName())
                        .lastName(user.getLastName())
                        .role(user.getRole() != null ? user.getRole().name() : "USER")
                        .build())
                .build();
    }
}
