package com.caresync.backend.modules.notification.service;

import com.caresync.backend.modules.notification.entity.FcmToken;
import com.caresync.backend.modules.notification.repository.FcmTokenRepository;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class FcmService {

    private final FcmTokenRepository fcmTokenRepository;

    public void sendNotificationToUser(UUID userId, String title, String body) {
        List<FcmToken> tokens = fcmTokenRepository.findAllByUserId(userId);
        for (FcmToken token : tokens) {
            try {
                Message message = Message.builder()
                        .setToken(token.getToken())
                        .setNotification(Notification.builder()
                                .setTitle(title)
                                .setBody(body)
                                .build())
                        .build();
                String response = FirebaseMessaging.getInstance().send(message);
                log.info("Successfully sent FCM message: {}", response);
            } catch (Exception e) {
                log.error("Failed to send FCM message to token: {}", token.getToken(), e);
            }
        }
    }
}
