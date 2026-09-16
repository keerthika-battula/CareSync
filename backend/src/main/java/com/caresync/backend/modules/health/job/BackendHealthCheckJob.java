package com.caresync.backend.modules.health.job;

import jakarta.annotation.PostConstruct;
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
 * ARCHITECTURE & ENVIRONMENT VARIABLE BINDING:
 * =========================================================================================
 * - Reads EXTERNAL_PING_URL from the Render environment (or system property).
 * - Reads EXTERNAL_PING_ENABLED (defaults to true in production; false in test profile).
 * - All log statements sanitize URLs to prevent query token/credential leaks.
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

    @Value("${EXTERNAL_PING_ENABLED:${caresync.health-check.ping-enabled:true}}")
    private boolean pingEnabled;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(8))
            .build();

    @PostConstruct
    public void init() {
        String resolvedUrl = resolveTargetUrl();
        boolean resolvedEnabled = resolvePingEnabled();
        String host = extractHost(resolvedUrl);
        String path = extractPath(resolvedUrl);

        if (resolvedEnabled && resolvedUrl != null && !resolvedUrl.isBlank()) {
            log.info("[CareSync Health Job Config] Initialized. Ping Enabled: true | Target Host: [{}] | Path: [{}] | Interval: 5 minutes",
                    host, path);
        } else if (!resolvedEnabled) {
            log.info("[CareSync Health Job Config] Initialized. Ping Enabled: false (Pings disabled for this profile/environment)");
        } else {
            log.warn("[CareSync Health Job Config] Initialized. Ping Enabled: true | Target URL: [UNCONFIGURED] -> Add EXTERNAL_PING_URL in Render Dashboard to enable external keep-alive pings");
        }
    }

    private String resolveTargetUrl() {
        if (externalPingUrl != null && !externalPingUrl.trim().isEmpty()) {
            return externalPingUrl.trim();
        }
        String sysEnv = System.getenv("EXTERNAL_PING_URL");
        if (sysEnv != null && !sysEnv.trim().isEmpty()) {
            return sysEnv.trim();
        }
        String sysEnvLower = System.getenv("external_ping_url");
        if (sysEnvLower != null && !sysEnvLower.trim().isEmpty()) {
            return sysEnvLower.trim();
        }
        return null;
    }

    private boolean resolvePingEnabled() {
        String envEnabled = System.getenv("EXTERNAL_PING_ENABLED");
        if (envEnabled != null && !envEnabled.trim().isEmpty()) {
            return Boolean.parseBoolean(envEnabled.trim());
        }
        return pingEnabled;
    }

    private String extractHost(String rawUrl) {
        if (rawUrl == null || rawUrl.isBlank()) return "N/A";
        try {
            URI uri = URI.create(rawUrl.trim());
            return uri.getHost() != null ? uri.getHost() : "N/A";
        } catch (Exception e) {
            return "invalid-url";
        }
    }

    private String extractPath(String rawUrl) {
        if (rawUrl == null || rawUrl.isBlank()) return "/";
        try {
            URI uri = URI.create(rawUrl.trim());
            return (uri.getPath() != null && !uri.getPath().isEmpty()) ? uri.getPath() : "/";
        } catch (Exception e) {
            return "/";
        }
    }

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
        boolean isEnabled = resolvePingEnabled();
        String targetUrl = resolveTargetUrl();
        boolean httpPingSuccess = false;
        int httpStatusCode = 0;
        long httpDurationMs = 0;
        String targetHost = extractHost(targetUrl);
        String targetPath = extractPath(targetUrl);

        if (isEnabled) {
            if (targetUrl != null && !targetUrl.isBlank()) {
                long httpStart = System.currentTimeMillis();
                try {
                    HttpRequest request = HttpRequest.newBuilder()
                            .uri(URI.create(targetUrl))
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
                        log.info("[CareSync Health Job] External ping SUCCESS -> Host: [{}], Path: [{}], Status: [{}], Latency: [{}ms]",
                                targetHost, targetPath, httpStatusCode, httpDurationMs);
                    } else {
                        log.warn("[CareSync Health Job] External ping returned non-2xx -> Host: [{}], Path: [{}], Status: [{}], Latency: [{}ms]",
                                targetHost, targetPath, httpStatusCode, httpDurationMs);
                    }
                } catch (Exception e) {
                    httpDurationMs = System.currentTimeMillis() - httpStart;
                    log.error("[CareSync Health Job] External ping FAILED -> Host: [{}], Path: [{}], Error: [{}], Latency: [{}ms]",
                            targetHost, targetPath, e.getMessage(), httpDurationMs);
                }
            } else {
                log.warn("[CareSync Health Job] EXTERNAL_PING_URL environment variable is not configured or empty. External ping skipped. (Set EXTERNAL_PING_URL in Render Dashboard -> Environment to enable)");
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

        log.info("[CareSync Health Job] Health check cycle complete (total: {}ms) | DB: {} | External Ping: {} (Host: [{}], Path: [{}], Status: [{}], Latency: [{}ms]) | Heap: {}MB/{}MB | Active Threads: {} | Uptime: {}s",
                durationMs,
                dbHealthy ? "UP" : "DOWN (" + dbError + ")",
                httpPingSuccess ? "UP" : (isEnabled && targetUrl != null && !targetUrl.isBlank() ? "FAILED" : "SKIPPED/UNSET"),
                targetHost,
                targetPath,
                httpStatusCode,
                httpDurationMs,
                usedMemoryMb,
                maxMemoryMb,
                activeThreads,
                uptimeSeconds);
    }
}
