package com.caresync.backend.modules.auth.repository;

import com.caresync.backend.modules.auth.entity.PasswordResetToken;
import com.caresync.backend.modules.auth.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, UUID> {

    Optional<PasswordResetToken> findFirstByEmailAndUsedAtIsNullOrderByCreatedAtDesc(String email);

    Optional<PasswordResetToken> findFirstByUserAndUsedAtIsNullOrderByCreatedAtDesc(User user);

    Optional<PasswordResetToken> findFirstByUserOrderByCreatedAtDesc(User user);

    List<PasswordResetToken> findAllByUserAndUsedAtIsNull(User user);
}
