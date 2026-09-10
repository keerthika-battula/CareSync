import 'dart:typed_data';
import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/core/constants/app_constants.dart';
import 'package:caresync/features/documents/data/models/document_models.dart';
import 'package:caresync/features/documents/presentation/providers/document_provider.dart';
import 'package:caresync/shared/widgets/empty_state_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String _selectedFilter = 'ALL';
  String _searchQuery = '';

  static const _filters = [
    ('ALL', 'All'),
    (AppConstants.docPrescription, 'Prescription'),
    (AppConstants.docLabReport, 'Lab Report'),
    (AppConstants.docMedicalReport, 'Medical'),
    (AppConstants.docInsurance, 'Insurance'),
    ('OTHER', 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Health Documents', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh documents',
            onPressed: () => ref.read(documentProvider.notifier).loadDocuments(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _filters
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f.$2),
                        selected: _selectedFilter == f.$1,
                        onSelected: (_) => setState(() => _selectedFilter = f.$1),
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _selectedFilter == f.$1 ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: _selectedFilter == f.$1 ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search documents by title or filename...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          const SizedBox(height: 8),

          // Document list
          Expanded(
            child: docsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('Failed to load documents: $err', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.read(documentProvider.notifier).loadDocuments(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (documents) {
                final filtered = documents.where((doc) {
                  final matchesFilter = _selectedFilter == 'ALL' || doc.documentType == _selectedFilter;
                  if (!matchesFilter) return false;
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return doc.title.toLowerCase().contains(q) ||
                      doc.fileName.toLowerCase().contains(q) ||
                      (doc.description ?? '').toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.folder_open_outlined,
                    title: documents.isEmpty ? 'No documents yet' : 'No documents match your filter',
                    subtitle: documents.isEmpty
                        ? 'Upload prescriptions, test reports, and insurance documents to keep them safely organized.'
                        : 'Try changing your search term or filter category.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    return _buildDocCard(doc);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUploadDocument,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Document'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDocCard(HealthcareDocumentModel doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        doc.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        doc.documentType.replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  doc.fileName,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (doc.formattedFileSize.isNotEmpty) ...[
                      const Icon(Icons.data_usage, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(doc.formattedFileSize, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                      const SizedBox(width: 12),
                    ],
                    if (doc.documentDate != null) ...[
                      const Icon(Icons.calendar_today, size: 13, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(doc.documentDate!, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ],
                ),
                if (doc.description != null && doc.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    doc.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
            onSelected: (val) {
              if (val == 'open') {
                ref.read(documentProvider.notifier).downloadDocument(doc, openInNewTab: true);
              } else if (val == 'download') {
                ref.read(documentProvider.notifier).downloadDocument(doc, openInNewTab: false);
              } else if (val == 'delete') {
                _confirmDeleteDocument(doc);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Open in Browser'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Download'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file data'), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      if (!mounted) return;
      _showUploadDialog(file.name, file.bytes!, file.size);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showUploadDialog(String fileName, Uint8List fileBytes, int fileSize) {
    final titleController = TextEditingController(text: fileName);
    final descController = TextEditingController();
    String docType = 'PRESCRIPTION';
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Upload Document', style: TextStyle(fontWeight: FontWeight.bold)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                Text('${(fileSize / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Document Title *',
                        hintText: 'e.g. Blood Test Results',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: docType,
                      decoration: const InputDecoration(
                        labelText: 'Document Type',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'PRESCRIPTION', child: Text('Prescription')),
                        DropdownMenuItem(value: 'LAB_REPORT', child: Text('Lab Report')),
                        DropdownMenuItem(value: 'MEDICAL_REPORT', child: Text('Medical Report')),
                        DropdownMenuItem(value: 'INSURANCE', child: Text('Insurance')),
                        DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => docType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'e.g., Annual checkup diagnostics',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSubmitting = true);
                      try {
                        await ref.read(documentProvider.notifier).uploadDocument(
                              bytes: fileBytes,
                              fileName: fileName,
                              title: titleController.text.trim(),
                              documentType: docType,
                              description: descController.text.trim(),
                            );
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Document uploaded successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDocument(HealthcareDocumentModel doc) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Document', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete "${doc.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ref.read(documentProvider.notifier).deleteDocument(doc.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document deleted successfully'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
