package com.caresync.backend.modules.reminder.service;

import com.caresync.backend.modules.medicine.entity.Medicine;
import com.caresync.backend.modules.medicine.entity.RefillAlert;
import com.caresync.backend.modules.medicine.repository.RefillAlertRepository;
import com.caresync.backend.modules.notification.service.FcmService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class RefillPredictionService {

    private final RefillAlertRepository refillAlertRepository;
    private final FcmService fcmService;

    public void checkRefill(Medicine medicine) {
        if (medicine.getCurrentStock() != null && medicine.getRefillThreshold() != null) {
            if (medicine.getCurrentStock() <= medicine.getRefillThreshold()) {
                boolean alreadyAlerted = refillAlertRepository.findByMedicineIdAndStatus(medicine.getId(), "ACTIVE").isPresent();
                if (!alreadyAlerted) {
                    RefillAlert alert = RefillAlert.builder()
                            .medicine(medicine)
                            .status("ACTIVE")
                            .build();
                    refillAlertRepository.save(alert);
                    
                    fcmService.sendNotificationToUser(
                            medicine.getFamilyMember().getUser().getId(),
                            "Refill Alert: " + medicine.getName(),
                            "You have " + medicine.getCurrentStock() + " remaining. Time to refill!"
                    );
                }
            }
        }
    }
}
