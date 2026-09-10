class HealthcareDocumentModel {
  final String id;
  final String documentType;
  final String title;
  final String fileName;
  final String documentDate;

  HealthcareDocumentModel({
    required this.id,
    required this.documentType,
    required this.title,
    required this.fileName,
    required this.documentDate,
  });

  factory HealthcareDocumentModel.fromJson(Map<String, dynamic> json) {
    return HealthcareDocumentModel(
      id: json['id'],
      documentType: json['documentType'],
      title: json['title'],
      fileName: json['fileName'],
      documentDate: json['documentDate'],
    );
  }
}
