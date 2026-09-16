package com.caresync.backend.modules.health.job;

import lombok.extern.slf4j.Slf4j;
import org.quartz.DisallowConcurrentExecution;
import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.MemoryUsage;
import java.lang.management.RuntimeMXBean;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;

/**
 * Lightweight Quartz Job that runs every 10 minutes to verify backend health,
 * keep active database connection pools warm, monitor JVM resource usage, and
 * send an HTTP GET request to the deployed public Render health endpoint.
 *
 * =========================================================================================
 * ARCHITECTURE & RENDER FREE-TIER LIFECYCLE NOTE:
 * =========================================================================================
 * 1. HOW THE HTTP GET REQUEST INTERACTS WITH RENDER:
 *    - When the Spring Boot container is RUNNING / AWAKE, this job executes every 10 minutes.
 *    - It sends an outbound HTTP GET request to the deployed Render URL (e.g.
 *      https://caresync-4dfr.onrender.com/health).
 *    - This request exits the container, routes through Cloudflare / Render's public edge
 *      load balancer, and arrives back as an INBOUND HTTP request to the service.
 *    - Render's edge router recognizes this inbound HTTP traffic and resets the 15-minute
 *      idle inactivity timer back to zero, maintaining active container status.
 *
 * 2. CRITICAL LIMITATION (WHEN THE CONTAINER IS ASLEEP):
 *    - If Render puts the free-tier service to sleep (e.g., during initial deployment,
 *      platform restarts, or zero activity exceeding 15 minutes before the first trigger),
 *      the entire JVM and its internal threads (including Quartz) are SUSPENDED.
 *    - An internal Quartz job CANNOT wake up a sleeping container from the inside because
 *      its scheduler process is paused along with the JVM.
 *    - Container wake-up requires an external inbound request (such as a user accessing
 *      the CareSync frontend / API, or an external uptime service).
 *    - Once awakened, this Quartz job resumes executing every 10 minutes and keeps
 *      Render awake for subsequent cycles.
 * =========================================================================================
 */
@Component
@DisallowConcurrentExecution
@Slf4j
public class BackendHealthCheckJob implements Job {

    @Autowired(required = false)
    private DataSource dataSource;

    @Value("${caresync.health-check.ping-url:https://caresync-4dfr.onrender.com/health}")
    private String healthCheckUrl;

    @Value("${caresync.health-check.ping-enabled:true}")
    private boolean pingEnabled;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(8))
            .build();

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
            dbHealthy = true;
        }

        // 2. Perform Outbound HTTP GET Ping to Public Deployed Health Endpoint
        boolean httpPingSuccess = false;
        int httpStatusCode = 0;
        long httpDurationMs = 0;

        if (pingEnabled && healthCheckUrl != null && !healthCheckUrl.isBlank()) {
            long httpStart = System.currentTimeMillis();
            try {
                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(healthCheckUrl))
                        .header("User-Agent", "CareSync-InternalQuartz/1.0")
                        .header("Accept", "application/json, text/plain, */*")
                        .timeout(Duration.ofSeconds(10))
                        .GET()
                        .build();

                HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
                httpStatusCode = response.statusCode();
                httpDurationMs = System.currentTimeMillis() - httpStart;

                if (httpStatusCode >= 200 && httpStatusCode < 400) {
                    httpPingSuccess = true;
                    log.info("[CareSync Health Job] Deployed health endpoint ping SUCCESS -> {} (Status: {}, Duration: {}ms)",
                            healthCheckUrl, httpStatusCode, httpDurationMs);
                } else {
                    log.warn("[CareSync Health Job] Deployed health endpoint returned non-2xx status -> {} (Status: {})",
                            healthCheckUrl, httpStatusCode);
                }
            } catch (Exception e) {
                httpDurationMs = System.currentTimeMillis() - httpStart;
                log.warn("[CareSync Health Job] HTTP ping to {} failed or timed out ({}ms): {}",
                        healthCheckUrl, httpDurationMs, e.getMessage());
            }
        }

        // 3. Collect JVM Metrics (Heap Memory & Thread count)
        MemoryMXBean memoryBean = ManagementFactory.getMemoryMXBean();
        MemoryUsage heapUsage = memoryBean.getHeapMemoryUsage();
        long usedMemoryMb = heapUsage.getUsed() / (1024 * 1024);
        long maxMemoryMb = heapUsage.getMax() / (1024 * 1024);

        RuntimeMXBean runtimeBean = ManagementFactory.getRuntimeMXBean();
        long uptimeSeconds = runtimeBean.getUptime() / 1000;
        int activeThreads = Thread.activeCount();

        long durationMs = System.currentTimeMillis() - startTime;

        log.info("[CareSync Health Job] Health check cycle complete (total: {}ms) | DB: {} | HTTP Ping: {} (Status: {}) | Heap: {}MB/{}MB | Active Threads: {} | Uptime: {}s",
                durationMs,
                dbHealthy ? "UP" : "DOWN (" + dbError + ")",
                httpPingSuccess ? "UP" : (pingEnabled ? "FAILED/TIMEOUT" : "SKIPPED"),
                httpStatusCode,
                usedMemoryMb,
                maxMemoryMb,
                activeThreads,
                uptimeSeconds);
    }
}
