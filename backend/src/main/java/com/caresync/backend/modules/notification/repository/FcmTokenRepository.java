package com.caresync.backend.modules.notification.repository;

import com.caresync.backend.modules.notification.entity.FcmToken;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface FcmTokenRepository extends JpaRepository<FcmToken, UUID> {
    List<FcmToken> findAllByUserId(UUID userId);
}
