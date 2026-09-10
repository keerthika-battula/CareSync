package com.caresync.backend.modules.auth.service;

public interface EmailService {
    void sendPasswordResetEmail(String toEmail, String otpCode);
}
