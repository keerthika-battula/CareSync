package com.caresync.backend.modules.health;

import com.caresync.backend.modules.health.job.BackendHealthCheckJob;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.quartz.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
class BackendHealthCheckJobIntegrationTest {

    @Autowired
    private Scheduler scheduler;

    @Autowired
    private BackendHealthCheckJob backendHealthCheckJob;

    @Test
    @DisplayName("Verify Quartz scheduler registers the 10-minute backend health-check JobDetail")
    void testBackendHealthCheckJobIsRegistered() throws SchedulerException {
        JobKey jobKey = JobKey.jobKey("backendHealthCheckJob", "system-maintenance");
        assertTrue(scheduler.checkExists(jobKey), "backendHealthCheckJob should be registered in Quartz scheduler");

        JobDetail jobDetail = scheduler.getJobDetail(jobKey);
        assertNotNull(jobDetail);
        assertEquals(BackendHealthCheckJob.class, jobDetail.getJobClass());
        assertTrue(jobDetail.isDurable());
    }

    @Test
    @DisplayName("Verify Quartz scheduler registers the 5-minute recurring Trigger")
    void testBackendHealthCheckTriggerIsRegistered() throws SchedulerException {
        TriggerKey triggerKey = TriggerKey.triggerKey("backendHealthCheckTrigger", "system-maintenance");
        assertTrue(scheduler.checkExists(triggerKey), "backendHealthCheckTrigger should be registered in Quartz scheduler");

        Trigger trigger = scheduler.getTrigger(triggerKey);
        assertNotNull(trigger);
        assertTrue(trigger instanceof SimpleTrigger, "Trigger should be a SimpleTrigger configured with 5-minute interval");

        SimpleTrigger simpleTrigger = (SimpleTrigger) trigger;
        assertEquals(5 * 60 * 1000L, simpleTrigger.getRepeatInterval(), "Repeat interval should be 5 minutes (300,000 ms)");
    }

    @Test
    @DisplayName("Verify direct execution of BackendHealthCheckJob completes without errors")
    void testDirectExecutionOfHealthCheckJob() {
        assertDoesNotThrow(() -> backendHealthCheckJob.execute(null));
    }
}
