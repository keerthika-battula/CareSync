package com.caresync.backend.modules.reminder.job;

import com.caresync.backend.modules.medicine.entity.Medicine;
import com.caresync.backend.modules.medicine.repository.MedicineRepository;
import com.caresync.backend.modules.notification.service.FcmService;
import org.quartz.Job;
import org.quartz.JobDataMap;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class MedicineReminderJob implements Job {

    @Autowired
    private MedicineRepository medicineRepository;

    @Autowired
    private FcmService fcmService;

    @Override
    public void execute(JobExecutionContext context) throws JobExecutionException {
        JobDataMap dataMap = context.getJobDetail().getJobDataMap();
        String medicineIdStr = dataMap.getString("medicineId");

        if (medicineIdStr != null) {
            UUID medicineId = UUID.fromString(medicineIdStr);
            medicineRepository.findById(medicineId).ifPresent(medicine -> {
                String title = "Time for your medicine: " + medicine.getName();
                String body = "Dosage: " + medicine.getDosage();
                if (medicine.getFamilyMember() != null) {
                    title = "Time for " + medicine.getFamilyMember().getName() + "'s medicine: " + medicine.getName();
                }
                fcmService.sendNotificationToUser(medicine.getFamilyMember().getUser().getId(), title, body);
            });
        }
    }
}
