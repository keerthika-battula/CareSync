class MedicineModel {
  final String id;
  final String name;
  final String? dosage;
  final String? frequency;
  final String? notes;
  final String? startDate;
  final String? endDate;
  final int currentQuantity;
  final int refillThreshold;
  final bool isActive;
  final String? familyMemberId;

  MedicineModel({
    required this.id,
    required this.name,
    this.dosage,
    this.frequency,
    this.notes,
    this.startDate,
    this.endDate,
    required this.currentQuantity,
    required this.refillThreshold,
    required this.isActive,
    this.familyMemberId,
  });

  bool get isLowStock => currentQuantity <= refillThreshold;

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      dosage: json['dosage'],
      frequency: json['frequency'],
      notes: json['notes'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      currentQuantity: (json['currentQuantity'] as num?)?.toInt() ?? 0,
      refillThreshold: (json['refillThreshold'] as num?)?.toInt() ?? 7,
      isActive: json['isActive'] ?? true,
      familyMemberId: json['familyMemberId'],
    );
  }
}
