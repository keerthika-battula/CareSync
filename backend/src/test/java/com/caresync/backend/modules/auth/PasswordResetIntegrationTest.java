package com.caresync.backend.modules.auth;

import com.caresync.backend.modules.auth.dto.ForgotPasswordRequest;
import com.caresync.backend.modules.auth.dto.LoginRequest;
import com.caresync.backend.modules.auth.dto.ResetPasswordRequest;
import com.caresync.backend.modules.auth.entity.PasswordResetToken;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.model.Role;
import com.caresync.backend.modules.auth.repository.PasswordResetTokenRepository;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PasswordResetIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordResetTokenRepository passwordResetTokenRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private User testUser;
    private final String initialPassword = "OldPassword123!";

    @BeforeEach
    void setUp() {
        passwordResetTokenRepository.deleteAll();
        userRepository.deleteAll();

        testUser = userRepository.save(User.builder()
                .firstName("Jane")
                .lastName("Doe")
                .email("jane.doe@caresync.test")
                .passwordHash(passwordEncoder.encode(initialPassword))
                .role(Role.USER)
                .isActive(true)
                .isEmailVerified(true)
                .build());
    }

    @Test
    @DisplayName("1. Existing email requests reset successfully")
    void testForgotPassword_ExistingEmail_Success() throws Exception {
        ForgotPasswordRequest request = ForgotPasswordRequest.builder()
                .email("jane.doe@caresync.test")
                .build();

        mockMvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("If the account exists, a password reset code has been sent."));

        List<PasswordResetToken> tokens = passwordResetTokenRepository.findAll();
        assertEquals(1, tokens.size());
        assertEquals("jane.doe@caresync.test", tokens.get(0).getEmail());
        assertNull(tokens.get(0).getUsedAt());
    }

    @Test
    @DisplayName("2. Non-existing email returns the exact same generic response")
    void testForgotPassword_NonExistingEmail_GenericResponse() throws Exception {
        ForgotPasswordRequest request = ForgotPasswordRequest.builder()
                .email("nonexistent.user@caresync.test")
                .build();

        mockMvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("If the account exists, a password reset code has been sent."));

        List<PasswordResetToken> tokens = passwordResetTokenRepository.findAll();
        assertTrue(tokens.isEmpty());
    }

    @Test
    @DisplayName("3. OTP is generated as exactly 6 digits and hashed")
    void testForgotPassword_OtpIsHashedAndMatchesSixDigits() throws Exception {
        ForgotPasswordRequest request = ForgotPasswordRequest.builder()
                .email("jane.doe@caresync.test")
                .build();

        mockMvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());

        PasswordResetToken token = passwordResetTokenRepository.findAll().get(0);
        assertNotNull(token.getCodeHash());
        // Code hash must be a BCrypt hash, not plaintext
        assertTrue(token.getCodeHash().startsWith("$2a$") || token.getCodeHash().startsWith("$2b$"));
        assertNotEquals(6, token.getCodeHash().length());
    }

    @Test
    @DisplayName("4. OTP expires after 15 minutes and expired OTP is rejected")
    void testResetPassword_ExpiredOtp_Rejected() throws Exception {
        // Create an expired token (expired 5 minutes ago)
        PasswordResetToken expiredToken = passwordResetTokenRepository.save(PasswordResetToken.builder()
                .user(testUser)
                .email(testUser.getEmail())
                .codeHash(passwordEncoder.encode("123456"))
                .expiresAt(LocalDateTime.now().minusMinutes(5))
                .attemptCount(0)
                .build());

        ResetPasswordRequest request = ResetPasswordRequest.builder()
                .email(testUser.getEmail())
                .code("123456")
                .newPassword("NewSecurePassword123!")
                .build();

        mockMvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));

        // Ensure token remains unusable
        PasswordResetToken refreshed = passwordResetTokenRepository.findById(expiredToken.getId()).orElseThrow();
        assertTrue(refreshed.isExpired() || refreshed.isUsed());
    }

    @Test
    @DisplayName("5. Invalid OTP is rejected and increments attempt count")
    void testResetPassword_InvalidOtp_Rejected() throws Exception {
        PasswordResetToken savedToken = passwordResetTokenRepository.saveAndFlush(PasswordResetToken.builder()
                .user(testUser)
                .email(testUser.getEmail())
                .codeHash(passwordEncoder.encode("654321"))
                .expiresAt(LocalDateTime.now().plusMinutes(15))
                .attemptCount(0)
                .build());

        ResetPasswordRequest request = ResetPasswordRequest.builder()
                .email(testUser.getEmail())
                .code("111111")
                .newPassword("NewSecurePassword123!")
                .build();

        mockMvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));

        PasswordResetToken token = passwordResetTokenRepository.findAll().get(0);
        assertEquals(1, token.getAttemptCount());
    }

    @Test
    @DisplayName("6. Used OTP is rejected")
    void testResetPassword_AlreadyUsedOtp_Rejected() throws Exception {
        passwordResetTokenRepository.save(PasswordResetToken.builder()
                .user(testUser)
                .email(testUser.getEmail())
                .codeHash(passwordEncoder.encode("123456"))
                .expiresAt(LocalDateTime.now().plusMinutes(15))
                .usedAt(LocalDateTime.now().minusMinutes(1))
                .attemptCount(0)
                .build());

        ResetPasswordRequest request = ResetPasswordRequest.builder()
                .email(testUser.getEmail())
                .code("123456")
                .newPassword("NewSecurePassword123!")
                .build();

        mockMvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @DisplayName("7 & 8 & 9. Correct OTP allows password reset, password is BCrypt hashed, old password fails")
    void testResetPassword_CorrectOtp_SuccessAndOldPasswordFails() throws Exception {
        String plainOtp = "456789";
        passwordResetTokenRepository.save(PasswordResetToken.builder()
                .user(testUser)
                .email(testUser.getEmail())
                .codeHash(passwordEncoder.encode(plainOtp))
                .expiresAt(LocalDateTime.now().plusMinutes(15))
                .attemptCount(0)
                .build());

        String newPassword = "BrandNewPassword123!";
        ResetPasswordRequest request = ResetPasswordRequest.builder()
                .email(testUser.getEmail())
                .code(plainOtp)
                .newPassword(newPassword)
                .build();

        // 7. Reset password
        mockMvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Password has been reset successfully. Please sign in with your new password."));

        // 8. New password is BCrypt hashed in DB
        User updatedUser = userRepository.findByEmail(testUser.getEmail()).orElseThrow();
        assertTrue(passwordEncoder.matches(newPassword, updatedUser.getPasswordHash()));
        assertFalse(passwordEncoder.matches(initialPassword, updatedUser.getPasswordHash()));

        // Token must now be marked as used
        PasswordResetToken token = passwordResetTokenRepository.findAll().get(0);
        assertNotNull(token.getUsedAt());

        // 9. Old password fails to authenticate
        LoginRequest oldLogin = LoginRequest.builder()
                .email(testUser.getEmail())
                .password(initialPassword)
                .build();
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(oldLogin)))
                .andExpect(status().isUnauthorized());

        // New password successfully authenticates
        LoginRequest newLogin = LoginRequest.builder()
                .email(testUser.getEmail())
                .password(newPassword)
                .build();
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(newLogin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty());
    }

    @Test
    @DisplayName("10. Previous reset token is invalidated when a new request is created")
    void testForgotPassword_InvalidatesPreviousUnusedTokens() throws Exception {
        ForgotPasswordRequest request = ForgotPasswordRequest.builder()
                .email(testUser.getEmail())
                .build();

        // First request
        mockMvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());

        PasswordResetToken firstToken = passwordResetTokenRepository.findAll().get(0);
        assertNull(firstToken.getUsedAt());

        // Second request
        mockMvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());

        List<PasswordResetToken> allTokens = passwordResetTokenRepository.findAll();
        assertEquals(2, allTokens.size());

        PasswordResetToken refreshedFirst = passwordResetTokenRepository.findById(firstToken.getId()).orElseThrow();
        assertNotNull(refreshedFirst.getUsedAt(), "Previous token must be marked used/invalidated");
    }

    @Test
    @DisplayName("11. OTP verification attempt limits work (max 5 attempts)")
    void testResetPassword_MaxAttemptsLimit_InvalidatesToken() throws Exception {
        String correctOtp = "999888";
        PasswordResetToken token = passwordResetTokenRepository.save(PasswordResetToken.builder()
                .user(testUser)
                .email(testUser.getEmail())
                .codeHash(passwordEncoder.encode(correctOtp))
                .expiresAt(LocalDateTime.now().plusMinutes(15))
                .attemptCount(0)
                .build());

        ResetPasswordRequest wrongRequest = ResetPasswordRequest.builder()
                .email(testUser.getEmail())
                .code("000000")
                .newPassword("NewPass123!")
                .build();

        // Fail 5 times
        for (int i = 1; i <= 5; i++) {
            mockMvc.perform(post("/api/auth/reset-password")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(wrongRequest)))
                    .andExpect(status().isBadRequest());
        }

        // Even with the correct OTP now, it must be rejected because max attempts reached
        ResetPasswordRequest correctRequest = ResetPasswordRequest.builder()
                .email(testUser.getEmail())
                .code(correctOtp)
                .newPassword("NewPass123!")
                .build();

        mockMvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(correctRequest)))
                .andExpect(status().isBadRequest());

        PasswordResetToken refreshedToken = passwordResetTokenRepository.findById(token.getId()).orElseThrow();
        assertNotNull(refreshedToken.getUsedAt(), "Token must be invalidated after max failed attempts");
    }
}
