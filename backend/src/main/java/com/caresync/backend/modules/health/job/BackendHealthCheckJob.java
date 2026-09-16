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
 * Lightweight Quartz Job that runs every 5 minutes to verify backend health,
 * keep active database connection pools warm, monitor JVM resource usage, and
 * send an HTTP GET request to an external endpoint configured via environment variables.
 *
 * =========================================================================================
 * ARCHITECTURE & ENVIRONMENT VARIABLE NOTE:
 * =========================================================================================
 * The target URL is read dynamically from the EXTERNAL_PING_URL environment variable
 * configured in Render (or application properties).
 *
 * If EXTERNAL_PING_URL is not set, a warning is logged and the job safely continues
 * its internal database and JVM health checks without crashing the application.
 *
 * All HTTP requests include strict connection timeouts (8s) and request timeouts (10s),
 * logging the target host, response status code, and latency for full observability.
 * =========================================================================================
 */
@Component
@DisallowConcurrentExecution
@Slf4j
public class BackendHealthCheckJob implements Job {

    @Autowired(required = false)
    private DataSource dataSource;

    @Value("${EXTERNAL_PING_URL:${caresync.health-check.external-ping-url:}}")
    private String externalPingUrl;

    @Value("${caresync.health-check.ping-enabled:true}")
    private boolean pingEnabled;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(8))
            .build();

    @Override
    public void execute(JobExecutionContext context) throws JobExecutionException {
        long startTime = System.currentTimeMillis();
        log.info("[CareSync Health Job] Starting 5-minute scheduled backend health self-check...");

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

        // 2. Perform Outbound HTTP GET Ping to External Endpoint (Read from EXTERNAL_PING_URL)
        boolean httpPingSuccess = false;
        int httpStatusCode = 0;
        long httpDurationMs = 0;
        String targetHost = "N/A";

        if (pingEnabled) {
            if (externalPingUrl != null && !externalPingUrl.trim().isEmpty()) {
                String trimmedUrl = externalPingUrl.trim();
                try {
                    URI uri = URI.create(trimmedUrl);
                    targetHost = uri.getHost() != null ? uri.getHost() : trimmedUrl;
                } catch (Exception e) {
                    targetHost = trimmedUrl;
                }

                long httpStart = System.currentTimeMillis();
                try {
                    HttpRequest request = HttpRequest.newBuilder()
                            .uri(URI.create(trimmedUrl))
                            .header("User-Agent", "CareSync-ExternalPing/1.0")
                            .header("Accept", "application/json, text/plain, */*")
                            .timeout(Duration.ofSeconds(10))
                            .GET()
                            .build();

                    HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
                    httpStatusCode = response.statusCode();
                    httpDurationMs = System.currentTimeMillis() - httpStart;

                    if (httpStatusCode >= 200 && httpStatusCode < 400) {
                        httpPingSuccess = true;
                        log.info("[CareSync Health Job] External ping SUCCESS -> Host: [{}], URL: [{}], Status: [{}], Duration: [{}ms]",
                                targetHost, trimmedUrl, httpStatusCode, httpDurationMs);
                    } else {
                        log.warn("[CareSync Health Job] External ping returned non-2xx -> Host: [{}], URL: [{}], Status: [{}], Duration: [{}ms]",
                                targetHost, trimmedUrl, httpStatusCode, httpDurationMs);
                    }
                } catch (Exception e) {
                    httpDurationMs = System.currentTimeMillis() - httpStart;
                    log.error("[CareSync Health Job] External ping FAILED -> Host: [{}], URL: [{}], Error: [{}], Duration: [{}ms]",
                            targetHost, trimmedUrl, e.getMessage(), httpDurationMs);
                }
            } else {
                log.warn("[CareSync Health Job] EXTERNAL_PING_URL environment variable is not configured or empty. External ping skipped.");
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

        log.info("[CareSync Health Job] Health check cycle complete (total: {}ms) | DB: {} | External Ping: {} (Host: {}, Status: {}) | Heap: {}MB/{}MB | Active Threads: {} | Uptime: {}s",
                durationMs,
                dbHealthy ? "UP" : "DOWN (" + dbError + ")",
                httpPingSuccess ? "UP" : (pingEnabled && externalPingUrl != null && !externalPingUrl.isBlank() ? "FAILED" : "SKIPPED/UNSET"),
                targetHost,
                httpStatusCode,
                usedMemoryMb,
                maxMemoryMb,
                activeThreads,
                uptimeSeconds);
    }
}
