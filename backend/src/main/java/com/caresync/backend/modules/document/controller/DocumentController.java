package com.caresync.backend.modules.document.controller;

import com.caresync.backend.common.response.ApiResponse;
import com.caresync.backend.modules.document.dto.DocumentResponse;
import com.caresync.backend.modules.document.service.DocumentService;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/documents")
@RequiredArgsConstructor
public class DocumentController {

    private final DocumentService documentService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<DocumentResponse>>> getDocuments(Authentication auth) {
        List<DocumentResponse> documents = documentService.getUserDocuments(auth.getName());
        return ResponseEntity.ok(ApiResponse.success(documents));
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<DocumentResponse>> uploadDocument(
            Authentication auth,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "title", required = false) String title,
            @RequestParam(value = "documentType", required = false, defaultValue = "OTHER") String documentType,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "familyMemberId", required = false) UUID familyMemberId) throws Exception {

        DocumentResponse response = documentService.uploadDocument(
                auth.getName(),
                familyMemberId,
                documentType,
                title,
                description,
                file
        );
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Document uploaded successfully", response));
    }

    @GetMapping("/{id}/download")
    public ResponseEntity<Resource> downloadDocument(
            Authentication auth,
            @PathVariable UUID id) throws Exception {

        DocumentService.DocumentDownload download = documentService.downloadDocument(auth.getName(), id);
        InputStreamResource resource = new InputStreamResource(download.getInputStream());

        String encodedFilename = URLEncoder.encode(download.getFileName(), StandardCharsets.UTF_8).replace("+", "%20");

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + encodedFilename + "\"; filename*=UTF-8''" + encodedFilename)
                .contentType(MediaType.parseMediaType(download.getMimeType() != null ? download.getMimeType() : "application/octet-stream"))
                .body(resource);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteDocument(
            Authentication auth,
            @PathVariable UUID id) throws Exception {

        documentService.deleteDocument(auth.getName(), id);
        return ResponseEntity.ok(ApiResponse.success("Document deleted successfully", null));
    }
}
