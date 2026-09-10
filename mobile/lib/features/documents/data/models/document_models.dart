class HealthcareDocumentModel {
  final String id;
  final String? familyMemberId;
  final String? familyMemberName;
  final String documentType;
  final String title;
  final String? description;
  final String fileName;
  final int? fileSize;
  final String? mimeType;
  final String? documentDate;
  final String? createdAt;

  HealthcareDocumentModel({
    required this.id,
    this.familyMemberId,
    this.familyMemberName,
    required this.documentType,
    required this.title,
    this.description,
    required this.fileName,
    this.fileSize,
    this.mimeType,
    this.documentDate,
    this.createdAt,
  });

  String get formattedFileSize {
    if (fileSize == null || fileSize! <= 0) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory HealthcareDocumentModel.fromJson(Map<String, dynamic> json) {
    return HealthcareDocumentModel(
      id: json['id'] ?? '',
      familyMemberId: json['familyMemberId'],
      familyMemberName: json['familyMemberName'],
      documentType: json['documentType'] ?? 'OTHER',
      title: json['title'] ?? '',
      description: json['description'],
      fileName: json['fileName'] ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'],
      documentDate: json['documentDate'],
      createdAt: json['createdAt'],
    );
  }
}
