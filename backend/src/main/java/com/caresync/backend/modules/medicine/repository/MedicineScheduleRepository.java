package com.caresync.backend.modules.medicine.repository;

import com.caresync.backend.modules.medicine.entity.MedicineSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface MedicineScheduleRepository extends JpaRepository<MedicineSchedule, UUID> {
    List<MedicineSchedule> findAllByMedicineId(UUID medicineId);
    void deleteAllByMedicineId(UUID medicineId);
}
