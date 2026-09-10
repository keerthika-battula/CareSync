package com.caresync.backend.modules.document.dto;

import com.caresync.backend.modules.document.entity.HealthcareDocument;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class DocumentResponse {
    private UUID id;
    private UUID familyMemberId;
    private String familyMemberName;
    private String documentType;
    private String title;
    private String description;
    private String fileName;
    private Long fileSize;
    private String mimeType;
    private LocalDate documentDate;
    private LocalDateTime createdAt;

    public static DocumentResponse fromEntity(HealthcareDocument doc) {
        return DocumentResponse.builder()
                .id(doc.getId())
                .familyMemberId(doc.getFamilyMember() != null ? doc.getFamilyMember().getId() : null)
                .familyMemberName(doc.getFamilyMember() != null ? doc.getFamilyMember().getName() : "Self")
                .documentType(doc.getDocumentType())
                .title(doc.getTitle())
                .description(doc.getDescription())
                .fileName(doc.getFileName())
                .fileSize(doc.getFileSize())
                .mimeType(doc.getMimeType())
                .documentDate(doc.getDocumentDate())
                .createdAt(doc.getCreatedAt())
                .build();
    }
}
