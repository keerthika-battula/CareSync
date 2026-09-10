class ReminderOccurrenceModel {
  final String id;
  final String medicineId;
  final String medicineName;
  final String? dosage;
  final double dosagePerIntake;
  final String? dosageUnit;
  final int? currentStock;
  final int? refillThreshold;
  final String scheduledTime;
  final String? originalScheduledTime;
  final String? snoozedUntil;
  final String status;
  final String? actionTime;
  final int snoozeCount;

  ReminderOccurrenceModel({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    this.dosage,
    this.dosagePerIntake = 1.0,
    this.dosageUnit,
    this.currentStock,
    this.refillThreshold,
    required this.scheduledTime,
    this.originalScheduledTime,
    this.snoozedUntil,
    required this.status,
    this.actionTime,
    required this.snoozeCount,
  });

  bool get isTaken => status == 'TAKEN';
  bool get isSkipped => status == 'SKIPPED';
  bool get isSnoozed => status == 'SNOOZED';
  bool get isPending => status == 'PENDING';

  factory ReminderOccurrenceModel.fromJson(Map<String, dynamic> json) {
    return ReminderOccurrenceModel(
      id: json['id'] ?? '',
      medicineId: json['medicineId'] ?? '',
      medicineName: json['medicineName'] ?? '',
      dosage: json['dosage'],
      dosagePerIntake: (json['dosagePerIntake'] as num?)?.toDouble() ?? 1.0,
      dosageUnit: json['dosageUnit'],
      currentStock: (json['currentStock'] as num?)?.toInt(),
      refillThreshold: (json['refillThreshold'] as num?)?.toInt(),
      scheduledTime: json['scheduledTime'] ?? '',
      originalScheduledTime: json['originalScheduledTime'],
      snoozedUntil: json['snoozedUntil'],
      status: json['status'] ?? 'PENDING',
      actionTime: json['actionTime'],
      snoozeCount: (json['snoozeCount'] as num?)?.toInt() ?? 0,
    );
  }

  ReminderOccurrenceModel copyWith({
    String? id,
    String? medicineId,
    String? medicineName,
    String? dosage,
    double? dosagePerIntake,
    String? dosageUnit,
    int? currentStock,
    int? refillThreshold,
    String? scheduledTime,
    String? originalScheduledTime,
    String? snoozedUntil,
    String? status,
    String? actionTime,
    int? snoozeCount,
  }) {
    return ReminderOccurrenceModel(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      dosagePerIntake: dosagePerIntake ?? this.dosagePerIntake,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      currentStock: currentStock ?? this.currentStock,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      originalScheduledTime: originalScheduledTime ?? this.originalScheduledTime,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      status: status ?? this.status,
      actionTime: actionTime ?? this.actionTime,
      snoozeCount: snoozeCount ?? this.snoozeCount,
    );
  }
}

class SnoozeRequest {
  final int minutes;
  SnoozeRequest({required this.minutes});
  Map<String, dynamic> toJson() => {'minutes': minutes};
}
