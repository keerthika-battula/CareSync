package com.caresync.backend.modules.medicine.repository;

import com.caresync.backend.modules.medicine.entity.RefillAlert;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;
import java.util.Optional;

public interface RefillAlertRepository extends JpaRepository<RefillAlert, UUID> {
    Optional<RefillAlert> findByMedicineIdAndStatus(UUID medicineId, String status);
}
