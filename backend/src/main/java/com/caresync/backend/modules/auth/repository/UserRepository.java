package com.caresync.backend.modules.auth.repository;

import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.model.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);
    Optional<User> findByEmailIgnoreCase(String email);
    boolean existsByEmail(String email);
    boolean existsByEmailIgnoreCase(String email);

    Optional<User> findByUsername(String username);
    Optional<User> findByUsernameIgnoreCase(String username);
    boolean existsByUsername(String username);
    boolean existsByUsernameIgnoreCase(String username);

    @org.springframework.data.jpa.repository.Query("SELECT u FROM User u WHERE LOWER(u.email) = LOWER(:identifier) OR (u.username IS NOT NULL AND LOWER(u.username) = LOWER(:identifier))")
    Optional<User> findByEmailOrUsernameIgnoreCase(@org.springframework.data.repository.query.Param("identifier") String identifier);

    long countByRoleAndIsActiveTrue(Role role);

    List<User> findAllByIsActiveTrue();

    List<User> findAllByRoleAndIsActiveTrue(Role role);

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("SELECT u FROM User u WHERE u.role = :role AND u.isActive = true")
    List<User> findAllActiveAdminsForUpdate(@org.springframework.data.repository.query.Param("role") Role role);
}
