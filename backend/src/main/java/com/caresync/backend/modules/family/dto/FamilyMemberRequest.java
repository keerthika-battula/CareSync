package com.caresync.backend.modules.family.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import java.time.LocalDate;

@Data
public class FamilyMemberRequest {
    @NotBlank(message = "Name is required")
    private String name;

    @NotBlank(message = "Relationship is required")
    private String relationship;

    private LocalDate dateOfBirth;
}
