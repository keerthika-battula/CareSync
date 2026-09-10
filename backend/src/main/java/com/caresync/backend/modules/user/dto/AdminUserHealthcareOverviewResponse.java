package com.caresync.backend.modules.user.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminUserHealthcareOverviewResponse {
    private UUID userId;
    private long familyMembersCount;
    private long activeMedicinesCount;
    private long upcomingAppointmentsCount;
    private long totalDocumentsCount;
}
