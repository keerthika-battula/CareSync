package com.caresync.backend.modules.family.repository;

import com.caresync.backend.modules.family.entity.FamilyMember;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FamilyMemberRepository extends JpaRepository<FamilyMember, UUID> {
    List<FamilyMember> findAllByUserId(UUID userId);
    Optional<FamilyMember> findByIdAndUserId(UUID id, UUID userId);
    Optional<FamilyMember> findByUserIdAndIsSelfTrue(UUID userId);
}
