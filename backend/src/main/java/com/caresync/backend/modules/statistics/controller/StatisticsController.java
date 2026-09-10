package com.caresync.backend.modules.statistics.controller;

import com.caresync.backend.common.response.ApiResponse;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.statistics.service.StatisticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/statistics")
@RequiredArgsConstructor
public class StatisticsController {

    private final StatisticsService statisticsService;

    @GetMapping("/dashboard")
    public ApiResponse<Map<String, Object>> getDashboardStats(@AuthenticationPrincipal User user) {
        return ApiResponse.success(statisticsService.getDashboardStats(user.getId()));
    }
}
