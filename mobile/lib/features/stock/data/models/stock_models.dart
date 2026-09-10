class RefillAlertModel {
  final String id;
  final String medicineId;
  final String medicineName;
  final String status;
  final String? estimatedDepletionDate;

  RefillAlertModel({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.status,
    this.estimatedDepletionDate,
  });

  factory RefillAlertModel.fromJson(Map<String, dynamic> json) {
    return RefillAlertModel(
      id: json['id'],
      medicineId: json['medicineId'],
      medicineName: json['medicineName'],
      status: json['status'],
      estimatedDepletionDate: json['estimatedDepletionDate'],
    );
  }
}
