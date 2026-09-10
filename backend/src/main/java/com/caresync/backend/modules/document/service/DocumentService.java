package com.caresync.backend.modules.document.service;

import com.caresync.backend.modules.document.entity.HealthcareDocument;
import com.caresync.backend.modules.document.repository.DocumentRepository;
import com.caresync.backend.modules.family.entity.FamilyMember;
import com.caresync.backend.modules.family.repository.FamilyMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.io.InputStream;

@Service
@RequiredArgsConstructor
public class DocumentService {

    private final DocumentRepository documentRepository;
    private final FamilyMemberRepository familyMemberRepository;
    private final MinioService minioService;

    @Transactional
    public HealthcareDocument uploadDocument(UUID userId, UUID familyMemberId, String documentType, String title, String description, MultipartFile file) throws Exception {
        FamilyMember familyMember = familyMemberRepository.findById(familyMemberId).orElseThrow();
        if (!familyMember.getUser().getId().equals(userId)) throw new SecurityException("Unauthorized");

        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null) originalFilename = "unknown";
        String objectKey = userId.toString() + "/" + UUID.randomUUID().toString() + "_" + originalFilename.replaceAll("[^a-zA-Z0-9.\\-]", "_");

        minioService.uploadFile(objectKey, file);

        HealthcareDocument doc = HealthcareDocument.builder()
                .familyMember(familyMember)
                .documentType(documentType)
                .title(title)
                .description(description)
                .fileName(originalFilename)
                .filePath(objectKey)
                .fileSize(file.getSize())
                .mimeType(file.getContentType())
                .documentDate(LocalDate.now())
                .build();
        return documentRepository.save(doc);
    }

    @Transactional(readOnly = true)
    public List<HealthcareDocument> getUserDocuments(UUID userId) {
        return documentRepository.findAllByFamilyMemberUserId(userId);
    }

    @Transactional(readOnly = true)
    public InputStream downloadDocument(UUID userId, UUID documentId) throws Exception {
        HealthcareDocument doc = documentRepository.findById(documentId).orElseThrow();
        if (!doc.getFamilyMember().getUser().getId().equals(userId)) throw new SecurityException("Unauthorized");
        return minioService.downloadFile(doc.getFilePath());
    }

    @Transactional
    public void deleteDocument(UUID userId, UUID documentId) throws Exception {
        HealthcareDocument doc = documentRepository.findById(documentId).orElseThrow();
        if (!doc.getFamilyMember().getUser().getId().equals(userId)) throw new SecurityException("Unauthorized");
        minioService.deleteFile(doc.getFilePath());
        documentRepository.delete(doc);
    }
}
