package com.caresync.backend.modules.notification.entity;

import com.caresync.backend.common.entity.BaseEntity;
import com.caresync.backend.modules.auth.entity.User;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "fcm_tokens")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FcmToken extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String token;

    private String deviceType;

    @Column(nullable = false)
    @Builder.Default
    private boolean isActive = true;
}
