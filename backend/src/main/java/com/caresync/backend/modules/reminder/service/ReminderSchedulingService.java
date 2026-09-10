package com.caresync.backend.modules.reminder.service;

import com.caresync.backend.modules.reminder.job.MedicineReminderJob;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.quartz.*;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ReminderSchedulingService {

    private final Scheduler scheduler;

    public void scheduleMedicineReminder(UUID medicineId, String cronExpression) {
        try {
            JobDetail jobDetail = JobBuilder.newJob(MedicineReminderJob.class)
                    .withIdentity("medicine-job-" + medicineId.toString(), "medicine-reminders")
                    .usingJobData("medicineId", medicineId.toString())
                    .storeDurably()
                    .build();

            Trigger trigger = TriggerBuilder.newTrigger()
                    .withIdentity("medicine-trigger-" + medicineId.toString(), "medicine-reminders")
                    .withSchedule(CronScheduleBuilder.cronSchedule(cronExpression))
                    .build();

            scheduler.scheduleJob(jobDetail, trigger);
            log.info("Scheduled medicine reminder for {}", medicineId);
        } catch (SchedulerException e) {
            log.error("Failed to schedule medicine reminder", e);
        }
    }

    public void scheduleSnooze(com.caresync.backend.modules.reminder.entity.ReminderOccurrence occurrence, int minutes) {
        // Mock implementation
        log.info("Scheduling snooze for occurrence {} by {} minutes", occurrence.getId(), minutes);
    }
}
