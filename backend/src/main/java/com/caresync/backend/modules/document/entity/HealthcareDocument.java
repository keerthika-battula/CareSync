package com.caresync.backend.modules.document.entity;

import com.caresync.backend.common.entity.BaseEntity;
import com.caresync.backend.modules.family.entity.FamilyMember;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Entity
@Table(name = "documents")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HealthcareDocument extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "family_member_id", nullable = false)
    private FamilyMember familyMember;

    @Column(nullable = false)
    private String documentType; // PRESCRIPTION, LAB_REPORT, MEDICAL_REPORT, INSURANCE, OTHER

    @Column(nullable = false)
    private String title;

    private String description;

    @Column(nullable = false)
    private String fileName;

    @Column(nullable = false)
    private String filePath; // acts as object_key for MinIO

    private Long fileSize;

    private String mimeType;

    private LocalDate documentDate;
}
