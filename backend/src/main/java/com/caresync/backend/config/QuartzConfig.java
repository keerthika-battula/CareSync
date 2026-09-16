package com.caresync.backend.config;

import com.caresync.backend.modules.health.job.BackendHealthCheckJob;
import org.quartz.JobBuilder;
import org.quartz.JobDetail;
import org.quartz.SimpleScheduleBuilder;
import org.quartz.Trigger;
import org.quartz.TriggerBuilder;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Quartz Scheduler Configuration for CareSync.
 *
 * Reuses Spring Boot's primary Scheduler bean and configures custom Spring Bean Job Factory
 * for autowired dependency injection in Quartz Job instances.
 *
 * Configures the periodic 10-minute system health self-check job and trigger.
 */
@Configuration
public class QuartzConfig {

    private final ApplicationContext applicationContext;

    public QuartzConfig(ApplicationContext applicationContext) {
        this.applicationContext = applicationContext;
    }

    @Bean
    public AutowiringSpringBeanJobFactory springBeanJobFactory() {
        AutowiringSpringBeanJobFactory factory = new AutowiringSpringBeanJobFactory();
        factory.setApplicationContext(applicationContext);
        return factory;
    }

    @Bean(name = "backendHealthCheckJobDetail")
    public JobDetail backendHealthCheckJobDetail() {
        return JobBuilder.newJob(BackendHealthCheckJob.class)
                .withIdentity("backendHealthCheckJob", "system-maintenance")
                .withDescription("Periodic 10-minute CareSync backend self-health check")
                .storeDurably()
                .build();
    }

    @Bean(name = "backendHealthCheckTrigger")
    public Trigger backendHealthCheckTrigger(@Qualifier("backendHealthCheckJobDetail") JobDetail jobDetail) {
        return TriggerBuilder.newTrigger()
                .forJob(jobDetail)
                .withIdentity("backendHealthCheckTrigger", "system-maintenance")
                .withDescription("10-minute recurring trigger for CareSync backend health self-check")
                .withSchedule(SimpleScheduleBuilder.simpleSchedule()
                        .withIntervalInMinutes(10)
                        .repeatForever()
                        .withMisfireHandlingInstructionNextWithExistingCount())
                .build();
    }
}
