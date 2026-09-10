class MedicineModel {
  final String id;
  final String name;
  final String? dosage;
  final String? frequency;
  final int currentQuantity;
  final int refillThreshold;
  final bool isActive;

  MedicineModel({
    required this.id,
    required this.name,
    this.dosage,
    this.frequency,
    required this.currentQuantity,
    required this.refillThreshold,
    required this.isActive,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      currentQuantity: json['currentQuantity'] ?? 0,
      refillThreshold: json['refillThreshold'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}
