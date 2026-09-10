package com.caresync.backend.modules.document.service;

import com.caresync.backend.common.exception.ForbiddenException;
import com.caresync.backend.common.exception.ResourceNotFoundException;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.document.dto.DocumentResponse;
import com.caresync.backend.modules.document.entity.HealthcareDocument;
import com.caresync.backend.modules.document.repository.DocumentRepository;
import com.caresync.backend.modules.family.entity.FamilyMember;
import com.caresync.backend.modules.family.repository.FamilyMemberRepository;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DocumentService {

    private final DocumentRepository documentRepository;
    private final FamilyMemberRepository familyMemberRepository;
    private final UserRepository userRepository;
    private final MinioService minioService;

    @Getter
    @AllArgsConstructor
    public static class DocumentDownload {
        private final InputStream inputStream;
        private final String fileName;
        private final String mimeType;
        private final Long fileSize;
    }

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
                .documentType(sanitizeDocumentType(documentType))
                .title(title != null ? title : originalFilename)
                .description(description)
                .fileName(originalFilename)
                .filePath(objectKey)
                .fileSize(file.getSize())
                .mimeType(file.getContentType())
                .documentDate(LocalDate.now())
                .build();
        return documentRepository.save(doc);
    }

    @Transactional
    public DocumentResponse uploadDocument(
            String email,
            UUID familyMemberId,
            String documentType,
            String title,
            String description,
            MultipartFile file) throws Exception {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        FamilyMember familyMember;
        if (familyMemberId != null) {
            familyMember = familyMemberRepository.findById(familyMemberId)
                    .orElseThrow(() -> new ResourceNotFoundException("Family member not found"));
            if (!familyMember.getUser().getId().equals(user.getId())) {
                throw new ForbiddenException("Unauthorized to upload document for this family member");
            }
        } else {
            familyMember = getOrCreateSelfFamilyMember(user);
        }

        String validDocType = sanitizeDocumentType(documentType);
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || originalFilename.isBlank()) {
            originalFilename = "document_" + System.currentTimeMillis();
        }

        String objectKey = user.getId().toString() + "/" + UUID.randomUUID() + "_" + originalFilename.replaceAll("[^a-zA-Z0-9.\\-]", "_");

        minioService.uploadFile(objectKey, file);

        HealthcareDocument doc = HealthcareDocument.builder()
                .familyMember(familyMember)
                .documentType(validDocType)
                .title(title != null && !title.isBlank() ? title.trim() : originalFilename)
                .description(description)
                .fileName(originalFilename)
                .filePath(objectKey)
                .fileSize(file.getSize())
                .mimeType(file.getContentType() != null ? file.getContentType() : "application/octet-stream")
                .documentDate(LocalDate.now())
                .build();

        HealthcareDocument saved = documentRepository.save(doc);
        return DocumentResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<DocumentResponse> getUserDocuments(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return documentRepository.findAllByFamilyMemberUserId(user.getId())
                .stream()
                .map(DocumentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public DocumentDownload downloadDocument(String email, UUID documentId) throws Exception {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        HealthcareDocument doc = documentRepository.findById(documentId)
                .orElseThrow(() -> new ResourceNotFoundException("Document not found"));

        if (!doc.getFamilyMember().getUser().getId().equals(user.getId())) {
            throw new ForbiddenException("Unauthorized to access this document");
        }

        InputStream is = minioService.downloadFile(doc.getFilePath());
        return new DocumentDownload(is, doc.getFileName(), doc.getMimeType(), doc.getFileSize());
    }

    @Transactional
    public void deleteDocument(UUID userId, UUID documentId) throws Exception {
        HealthcareDocument doc = documentRepository.findById(documentId).orElseThrow();
        if (!doc.getFamilyMember().getUser().getId().equals(userId)) throw new SecurityException("Unauthorized");
        try {
            minioService.deleteFile(doc.getFilePath());
        } catch (Exception ignored) {
        }
        documentRepository.delete(doc);
    }

    @Transactional
    public void deleteDocument(String email, UUID documentId) throws Exception {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        HealthcareDocument doc = documentRepository.findById(documentId)
                .orElseThrow(() -> new ResourceNotFoundException("Document not found"));

        if (!doc.getFamilyMember().getUser().getId().equals(user.getId())) {
            throw new ForbiddenException("Unauthorized to delete this document");
        }

        try {
            minioService.deleteFile(doc.getFilePath());
        } catch (Exception ignored) {
        }
        documentRepository.delete(doc);
    }

    @Transactional(readOnly = true)
    public List<DocumentResponse> getDocumentsForUser(UUID userId) {
        return documentRepository.findAllByFamilyMemberUserId(userId)
                .stream()
                .map(DocumentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public DocumentDownload downloadDocumentForAdmin(UUID userId, UUID documentId) throws Exception {
        HealthcareDocument doc = documentRepository.findById(documentId)
                .orElseThrow(() -> new ResourceNotFoundException("Document not found"));

        if (!doc.getFamilyMember().getUser().getId().equals(userId)) {
            throw new ForbiddenException("Document does not belong to the specified user");
        }

        InputStream is = minioService.downloadFile(doc.getFilePath());
        return new DocumentDownload(is, doc.getFileName(), doc.getMimeType(), doc.getFileSize());
    }

    private FamilyMember getOrCreateSelfFamilyMember(User user) {
        return familyMemberRepository.findByUserIdAndIsSelfTrue(user.getId())
                .orElseGet(() -> {
                    String name = (user.getFirstName() != null ? user.getFirstName() : "") + " " +
                            (user.getLastName() != null ? user.getLastName() : "");
                    name = name.trim();
                    if (name.isEmpty()) {
                        name = "Myself";
                    }
                    FamilyMember selfMember = FamilyMember.builder()
                            .user(user)
                            .name(name)
                            .relationship("Self")
                            .isSelf(true)
                            .build();
                    return familyMemberRepository.save(selfMember);
                });
    }

    private String sanitizeDocumentType(String type) {
        if (type == null) return "OTHER";
        String upper = type.trim().toUpperCase();
        switch (upper) {
            case "PRESCRIPTION":
            case "LAB_REPORT":
            case "MEDICAL_REPORT":
            case "INSURANCE":
            case "OTHER":
                return upper;
            default:
                return "OTHER";
        }
    }
}
