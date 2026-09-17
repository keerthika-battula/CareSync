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
 * Lightweight Quartz Job that runs every 10 minutes to verify backend health,
 * keep active database connection pools warm, monitor JVM resource usage, and
 * send independent HTTP GET keep-alive pings to both deployed Render services:
 * 1. Backend: https://caresync-4dfr.onrender.com/health
 * 2. Frontend: https://caresync-web-rav8.onrender.com
 *
 * =========================================================================================
 * ARCHITECTURE & RESILIENCE DESIGN:
 * =========================================================================================
 * - Outbound pings to Backend and Frontend are executed independently; failure or timeout
 *   in one service does not prevent the other from being pinged.
 * - Public responses and summary logs do not expose internal DB status ("DB: UP").
 *   Internal connection pool validation is performed quietly.
 * - All log statements sanitize URLs, logging strictly the target Host, Path, HTTP Status,
 *   and Latency (ms) without exposing query parameters or tokens.
 * =========================================================================================
 */
@Component
@DisallowConcurrentExecution
@Slf4j
public class BackendHealthCheckJob implements Job {

    private static final String DEFAULT_BACKEND_URL = "https://caresync-4dfr.onrender.com/health";
    private static final String DEFAULT_FRONTEND_URL = "https://caresync-web-rav8.onrender.com";

    @Autowired(required = false)
    private DataSource dataSource;

    @Value("${caresync.health-check.backend-ping-url:${BACKEND_PING_URL:${EXTERNAL_PING_URL:https://caresync-4dfr.onrender.com/health}}}")
    private String backendPingUrl;

    @Value("${caresync.health-check.frontend-ping-url:${FRONTEND_PING_URL:${EXTERNAL_FRONTEND_URL:https://caresync-web-rav8.onrender.com}}}")
    private String frontendPingUrl;

    @Value("${caresync.health-check.ping-enabled:${EXTERNAL_PING_ENABLED:${HEALTH_CHECK_PING_ENABLED:true}}}")
    private boolean pingEnabled;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(8))
            .build();

    public record ProbeResult(
            boolean success,
            int statusCode,
            long latencyMs,
            String host,
            String path,
            String errorMessage
    ) {}

    @PostConstruct
    public void init() {
        boolean resolvedEnabled = resolvePingEnabled();
        String backendUrl = resolveBackendUrl();
        String frontendUrl = resolveFrontendUrl();
        String backendHost = extractHost(backendUrl);
        String backendPath = extractPath(backendUrl);
        String frontendHost = extractHost(frontendUrl);
        String frontendPath = extractPath(frontendUrl);

        if (resolvedEnabled) {
            log.info("[CareSync Health Job Config] Initialized. Ping Enabled: true | Interval: 10 minutes | Backend: [{}{}] | Frontend: [{}{}]",
                    backendHost, backendPath, frontendHost, frontendPath);
        } else {
            log.info("[CareSync Health Job Config] Initialized. Ping Enabled: false (Pings disabled for this profile/environment)");
        }
    }

    private String resolveBackendUrl() {
        if (backendPingUrl != null && !backendPingUrl.trim().isEmpty()) {
            return backendPingUrl.trim();
        }
        String sysEnvBackend = System.getenv("BACKEND_PING_URL");
        if (sysEnvBackend != null && !sysEnvBackend.trim().isEmpty()) {
            return sysEnvBackend.trim();
        }
        String sysEnvExt = System.getenv("EXTERNAL_PING_URL");
        if (sysEnvExt != null && !sysEnvExt.trim().isEmpty()) {
            return sysEnvExt.trim();
        }
        return DEFAULT_BACKEND_URL;
    }

    private String resolveFrontendUrl() {
        if (frontendPingUrl != null && !frontendPingUrl.trim().isEmpty()) {
            return frontendPingUrl.trim();
        }
        String sysEnvFrontend = System.getenv("FRONTEND_PING_URL");
        if (sysEnvFrontend != null && !sysEnvFrontend.trim().isEmpty()) {
            return sysEnvFrontend.trim();
        }
        String sysEnvExtFront = System.getenv("EXTERNAL_FRONTEND_URL");
        if (sysEnvExtFront != null && !sysEnvExtFront.trim().isEmpty()) {
            return sysEnvExtFront.trim();
        }
        return DEFAULT_FRONTEND_URL;
    }

    private boolean resolvePingEnabled() {
        String envEnabled = System.getenv("EXTERNAL_PING_ENABLED");
        if (envEnabled != null && !envEnabled.trim().isEmpty()) {
            return Boolean.parseBoolean(envEnabled.trim());
        }
        String envHealthEnabled = System.getenv("HEALTH_CHECK_PING_ENABLED");
        if (envHealthEnabled != null && !envHealthEnabled.trim().isEmpty()) {
            return Boolean.parseBoolean(envHealthEnabled.trim());
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

    private ProbeResult executeProbe(String targetUrl, String serviceName) {
        if (targetUrl == null || targetUrl.isBlank()) {
            return new ProbeResult(false, 0, 0, "N/A", "/", "URL unconfigured");
        }
        String host = extractHost(targetUrl);
        String path = extractPath(targetUrl);
        long start = System.currentTimeMillis();
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(targetUrl))
                    .header("User-Agent", "CareSync-QuartzKeepAlive/1.0")
                    .header("Accept", "application/json, text/html, text/plain, */*")
                    .timeout(Duration.ofSeconds(10))
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            int statusCode = response.statusCode();
            long latencyMs = System.currentTimeMillis() - start;
            boolean success = statusCode >= 200 && statusCode < 400;

            if (success) {
                log.info("[CareSync Health Job] {} ping SUCCESS -> Host: [{}], Path: [{}], Status: [{}], Latency: [{}ms]",
                        serviceName, host, path, statusCode, latencyMs);
            } else {
                log.warn("[CareSync Health Job] {} ping returned non-2xx -> Host: [{}], Path: [{}], Status: [{}], Latency: [{}ms]",
                        serviceName, host, path, statusCode, latencyMs);
            }
            return new ProbeResult(success, statusCode, latencyMs, host, path, null);
        } catch (Exception e) {
            long latencyMs = System.currentTimeMillis() - start;
            log.error("[CareSync Health Job] {} ping FAILED -> Host: [{}], Path: [{}], Error: [{}], Latency: [{}ms]",
                    serviceName, host, path, e.getMessage(), latencyMs);
            return new ProbeResult(false, 0, latencyMs, host, path, e.getMessage());
        }
    }

    private String formatProbeSummary(boolean isEnabled, ProbeResult result) {
        if (!isEnabled || result == null) {
            return "SKIPPED/DISABLED";
        }
        String statusLabel = result.success() ? "UP" : "FAILED";
        return String.format("%s (Host: [%s], Path: [%s], Status: [%d], Latency: [%dms])",
                statusLabel, result.host(), result.path(), result.statusCode(), result.latencyMs());
    }

    @Override
    public void execute(JobExecutionContext context) throws JobExecutionException {
        long startTime = System.currentTimeMillis();
        log.info("[CareSync Health Job] Starting 10-minute scheduled backend & frontend health probe...");

        // 1. Internal Database Connectivity Validation (Quiet internal check, not exposed in summary log)
        if (dataSource != null) {
            try (Connection connection = dataSource.getConnection()) {
                connection.isValid(3);
            } catch (SQLException e) {
                log.debug("[CareSync Health Job] Internal DataSource probe encountered exception: {}", e.getMessage());
            }
        }

        // 2. Perform Independent Outbound HTTP GET Pings (Backend & Frontend)
        boolean isEnabled = resolvePingEnabled();
        ProbeResult backendResult = null;
        ProbeResult frontendResult = null;

        if (isEnabled) {
            String backendUrl = resolveBackendUrl();
            backendResult = executeProbe(backendUrl, "Backend");

            String frontendUrl = resolveFrontendUrl();
            frontendResult = executeProbe(frontendUrl, "Frontend");
        }

        // 3. Collect JVM Metrics
        MemoryMXBean memoryBean = ManagementFactory.getMemoryMXBean();
        MemoryUsage heapUsage = memoryBean.getHeapMemoryUsage();
        long usedMemoryMb = heapUsage.getUsed() / (1024 * 1024);
        long maxMemoryMb = heapUsage.getMax() / (1024 * 1024);

        RuntimeMXBean runtimeBean = ManagementFactory.getRuntimeMXBean();
        long uptimeSeconds = runtimeBean.getUptime() / 1000;
        int activeThreads = Thread.activeCount();

        long durationMs = System.currentTimeMillis() - startTime;

        String backendSummary = formatProbeSummary(isEnabled, backendResult);
        String frontendSummary = formatProbeSummary(isEnabled, frontendResult);

        log.info("[CareSync Health Job] Health check cycle complete (total: {}ms) | Backend: {} | Frontend: {} | Heap: {}MB/{}MB | Active Threads: {} | Uptime: {}s",
                durationMs,
                backendSummary,
                frontendSummary,
                usedMemoryMb,
                maxMemoryMb,
                activeThreads,
                uptimeSeconds);
    }
}
