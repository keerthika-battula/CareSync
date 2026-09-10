package com.caresync.backend.modules.medicine.repository;

import com.caresync.backend.modules.medicine.entity.Medicine;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface MedicineRepository extends JpaRepository<Medicine, UUID> {
    List<Medicine> findAllByFamilyMemberUserIdAndIsActiveTrue(UUID userId);
}
