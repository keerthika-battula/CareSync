package com.caresync.backend.modules.health.job;

import lombok.extern.slf4j.Slf4j;
import org.quartz.DisallowConcurrentExecution;
import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.MemoryUsage;
import java.lang.management.RuntimeMXBean;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * Lightweight Quartz Job that runs every 10 minutes to verify backend health,
 * keep active database connection pools warm, and monitor JVM resource usage.
 *
 * =========================================================================================
 * ARCHITECTURE NOTE / RENDER FREE-TIER LIMITATION:
 * =========================================================================================
 * An internal Quartz job runs inside the same JVM / application process as the Spring Boot
 * backend. On cloud platforms with instance idle spindown (such as the Render Free Tier),
 * the hosting provider puts the entire container / JVM into a suspended or sleeping state
 * after 15 minutes of zero inbound external HTTP traffic.
 *
 * Because the JVM process itself is paused during spindown, the internal Quartz scheduler
 * thread is also paused and CANNOT wake up the sleeping container from the inside. Container
 * wake-up requires an external inbound HTTP request (e.g. user navigation or external ping).
 *
 * When the backend container is running / awake, this internal job executes periodically
 * every 10 minutes to:
 *   1. Validate database connectivity and refresh connection pool idle state.
 *   2. Monitor JVM memory heap utilization and thread count.
 *   3. Log health diagnostics without requiring authentication or exposing sensitive data.
 *   4. Operate strictly isolated from business reminder jobs (MedicineReminderJob).
 * =========================================================================================
 */
@Component
@DisallowConcurrentExecution
@Slf4j
public class BackendHealthCheckJob implements Job {

    @Autowired(required = false)
    private DataSource dataSource;

    @Override
    public void execute(JobExecutionContext context) throws JobExecutionException {
        long startTime = System.currentTimeMillis();
        log.info("[CareSync Health Job] Starting 10-minute scheduled backend health self-check...");

        boolean dbHealthy = false;
        String dbError = null;

        // 1. Check Database Connectivity (Lightweight connection probe)
        if (dataSource != null) {
            try (Connection connection = dataSource.getConnection()) {
                if (connection.isValid(3)) {
                    dbHealthy = true;
                } else {
                    dbError = "DataSource connection validation returned false (timeout 3s)";
                }
            } catch (SQLException e) {
                dbError = e.getMessage();
                log.warn("[CareSync Health Job] Database probe encountered an exception: {}", e.getMessage());
            }
        } else {
            // In environments without a configured DataSource, mark as healthy
            dbHealthy = true;
        }

        // 2. Collect JVM Metrics (Heap Memory & Thread count)
        MemoryMXBean memoryBean = ManagementFactory.getMemoryMXBean();
        MemoryUsage heapUsage = memoryBean.getHeapMemoryUsage();
        long usedMemoryMb = heapUsage.getUsed() / (1024 * 1024);
        long maxMemoryMb = heapUsage.getMax() / (1024 * 1024);

        RuntimeMXBean runtimeBean = ManagementFactory.getRuntimeMXBean();
        long uptimeSeconds = runtimeBean.getUptime() / 1000;
        int activeThreads = Thread.activeCount();

        long durationMs = System.currentTimeMillis() - startTime;

        if (dbHealthy) {
            log.info("[CareSync Health Job] Backend health self-check PASSED (duration: {}ms). " +
                            "Status: UP | DB: HEALTHY | Heap: {}MB/{}MB | Threads: {} | Uptime: {}s",
                    durationMs, usedMemoryMb, maxMemoryMb, activeThreads, uptimeSeconds);
        } else {
            log.error("[CareSync Health Job] Backend health self-check WARNING: Database check failed: {}. " +
                            "Status: DEGRADED | Heap: {}MB/{}MB | Duration: {}ms",
                    dbError, usedMemoryMb, maxMemoryMb, durationMs);
        }
    }
}
