package com.caresync.backend.modules.document.repository;

import com.caresync.backend.modules.document.entity.HealthcareDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface DocumentRepository extends JpaRepository<HealthcareDocument, UUID> {
    List<HealthcareDocument> findAllByFamilyMemberUserId(UUID userId);
}
