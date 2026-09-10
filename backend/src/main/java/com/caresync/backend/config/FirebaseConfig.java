package com.caresync.backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;

@Slf4j
@Configuration
public class FirebaseConfig {

    @Value("${caresync.firebase.credentials-path}")
    private String credentialsPath;

    @PostConstruct
    public void initialize() {
        if (FirebaseApp.getApps().isEmpty()) {
            try {
                InputStream serviceAccount;
                try {
                    serviceAccount = new ClassPathResource(credentialsPath).getInputStream();
                } catch (IOException e) {
                    log.warn("Firebase credentials file not found at '{}'. Push notifications will be unavailable. " +
                             "Add firebase-service-account.json to src/main/resources to enable FCM.", credentialsPath);
                    return;
                }

                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                FirebaseApp.initializeApp(options);
                log.info("Firebase initialized successfully.");
            } catch (IOException e) {
                log.error("Failed to initialize Firebase: {}", e.getMessage());
            }
        }
    }
}
