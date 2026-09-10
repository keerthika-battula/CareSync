class ReminderOccurrenceModel {
  final String id;
  final String medicineId;
  final String medicineName;
  final String scheduledTime;
  final String status;
  final int snoozeCount;

  ReminderOccurrenceModel({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.scheduledTime,
    required this.status,
    required this.snoozeCount,
  });

  factory ReminderOccurrenceModel.fromJson(Map<String, dynamic> json) {
    return ReminderOccurrenceModel(
      id: json['id'],
      medicineId: json['medicineId'],
      medicineName: json['medicineName'],
      scheduledTime: json['scheduledTime'],
      status: json['status'],
      snoozeCount: json['snoozeCount'] ?? 0,
    );
  }
}

class SnoozeRequest {
  final int minutes;
  SnoozeRequest({required this.minutes});
  Map<String, dynamic> toJson() => {'minutes': minutes};
}
