package com.caresync.backend.modules.auth.service;

import jakarta.mail.internet.MimeMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class EmailServiceImpl implements EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.host:}")
    private String mailHost;

    @Value("${spring.mail.username:}")
    private String mailUsername;

    @Value("${caresync.mail.from:no-reply@caresync.com}")
    private String mailFrom;

    @Value("${caresync.mail.dev-mode:false}")
    private boolean devMode;

    public EmailServiceImpl(@Autowired(required = false) JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    @Override
    public void sendPasswordResetEmail(String toEmail, String otpCode) {
        boolean smtpConfigured = mailSender != null &&
                mailHost != null && !mailHost.trim().isEmpty() &&
                mailUsername != null && !mailUsername.trim().isEmpty();

        if (smtpConfigured) {
            try {
                MimeMessage message = mailSender.createMimeMessage();
                MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
                helper.setFrom(mailFrom);
                helper.setTo(toEmail);
                helper.setSubject("CareSync — Password Reset Verification Code");

                String htmlContent = "<div style=\"font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 12px;\">"
                        + "<h2 style=\"color: #2563eb; margin-bottom: 4px;\">CareSync</h2>"
                        + "<p style=\"color: #64748b; font-size: 14px; margin-top: 0;\">Your Care. In Sync. On Time.</p>"
                        + "<hr style=\"border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;\" />"
                        + "<p style=\"color: #1e293b; font-size: 15px;\">Hello,</p>"
                        + "<p style=\"color: #334155; font-size: 14px; line-height: 1.5;\">We received a request to reset your CareSync account password. Use the 6-digit verification code below to complete the reset process:</p>"
                        + "<div style=\"background-color: #f1f5f9; padding: 18px; border-radius: 8px; text-align: center; margin: 24px 0;\">"
                        + "<span style=\"font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #0f172a;\">" + otpCode + "</span>"
                        + "</div>"
                        + "<p style=\"color: #e11d48; font-size: 13px; font-weight: 600;\">This code is valid for 15 minutes and can only be used once.</p>"
                        + "<p style=\"color: #64748b; font-size: 12px; line-height: 1.4; margin-top: 24px;\">Security Notice: If you did not request a password reset, please ignore this email. Your password will remain unchanged.</p>"
                        + "</div>";

                helper.setText(htmlContent, true);
                mailSender.send(message);
                log.info("Password reset email successfully dispatched to {}", maskEmail(toEmail));
                return;
            } catch (Exception ex) {
                log.error("Failed to send password reset email via SMTP to {}: {}", maskEmail(toEmail), ex.getMessage());
            }
        }

        // Fallback handling when SMTP is not configured or fails
        if (devMode) {
            log.info("[CARESYNC PASSWORD RESET OTP] Code for {} is: {} (Expires in 15m)", toEmail, otpCode);
        } else {
            log.error("SMTP mail service is not configured. Email could not be sent to {}.", maskEmail(toEmail));
        }
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) return "***";
        int atIndex = email.indexOf('@');
        String namePart = email.substring(0, atIndex);
        String domainPart = email.substring(atIndex);
        if (namePart.length() <= 2) {
            return namePart.charAt(0) + "***" + domainPart;
        }
        return namePart.substring(0, 2) + "***" + domainPart;
    }
}
