import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/core/constants/app_constants.dart';
import 'package:caresync/shared/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _selectedFilter = 'ALL';

  final List<_Document> _documents = [
    _Document(
      title: 'Blood Test Report — Aug 2026',
      type: AppConstants.docLabReport,
      date: DateTime(2026, 8, 20),
      fileSize: '1.2 MB',
      fileType: 'PDF',
    ),
    _Document(
      title: 'Cardiology Prescription',
      type: AppConstants.docPrescription,
      date: DateTime(2026, 8, 5),
      fileSize: '340 KB',
      fileType: 'PDF',
    ),
    _Document(
      title: 'Echo Cardiogram Report',
      type: AppConstants.docMedicalReport,
      date: DateTime(2026, 7, 18),
      fileSize: '3.8 MB',
      fileType: 'PDF',
    ),
    _Document(
      title: 'Health Insurance Policy',
      type: AppConstants.docInsurance,
      date: DateTime(2026, 1, 1),
      fileSize: '2.1 MB',
      fileType: 'PDF',
    ),
    _Document(
      title: 'HbA1c Test Report',
      type: AppConstants.docLabReport,
      date: DateTime(2026, 6, 10),
      fileSize: '890 KB',
      fileType: 'PDF',
    ),
  ];

  List<_Document> get _filteredDocuments {
    if (_selectedFilter == 'ALL') return _documents;
    return _documents.where((d) => d.type == _selectedFilter).toList();
  }

  static const _filters = [
    ('ALL', 'All'),
    (AppConstants.docPrescription, 'Prescription'),
    (AppConstants.docLabReport, 'Lab Report'),
    (AppConstants.docMedicalReport, 'Medical'),
    (AppConstants.docInsurance, 'Insurance'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDocuments;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
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
                        onSelected: (_) =>
                            setState(() => _selectedFilter = f.$1),
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _selectedFilter == f.$1
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: _selectedFilter == f.$1
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          // Document list
          Expanded(
            child: filtered.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.folder_open_outlined,
                    title: 'No Documents',
                    subtitle: 'Upload your health documents to keep them safe.',
                    actionLabel: 'Upload Document',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _DocumentCard(document: filtered[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: open file picker and upload
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }
}

class _Document {
  const _Document({
    required this.title,
    required this.type,
    required this.date,
    required this.fileSize,
    required this.fileType,
  });

  final String title;
  final String type;
  final DateTime date;
  final String fileSize;
  final String fileType;
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final _Document document;

  Color get _typeColor {
    switch (document.type) {
      case AppConstants.docPrescription:
        return AppColors.primary;
      case AppConstants.docLabReport:
        return AppColors.secondary;
      case AppConstants.docMedicalReport:
        return AppColors.success;
      case AppConstants.docInsurance:
        return AppColors.warning;
      default:
        return AppColors.textLight;
    }
  }

  IconData get _typeIcon {
    switch (document.type) {
      case AppConstants.docPrescription:
        return Icons.medication_outlined;
      case AppConstants.docLabReport:
        return Icons.science_outlined;
      case AppConstants.docMedicalReport:
        return Icons.medical_information_outlined;
      case AppConstants.docInsurance:
        return Icons.shield_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String get _typeLabel {
    switch (document.type) {
      case AppConstants.docPrescription:
        return 'Prescription';
      case AppConstants.docLabReport:
        return 'Lab Report';
      case AppConstants.docMedicalReport:
        return 'Medical Report';
      case AppConstants.docInsurance:
        return 'Insurance';
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: _typeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${document.fileType} • ${document.fileSize}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, yyyy').format(document.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textLight),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
