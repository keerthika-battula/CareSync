package com.caresync.backend.modules.family.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
public class FamilyMemberResponse {
    private UUID id;
    private String name;
    private String relationship;
    private LocalDate dateOfBirth;
}
