class AppointmentModel {
  final String id;
  final String? familyMemberId;
  final String? familyMemberName;
  final String doctorName;
  final String hospitalClinic;
  final String appointmentDate;
  final String appointmentTime;
  final String? purpose;
  final String? notes;
  final String status;
  final int? reminderMinutesBefore;

  AppointmentModel({
    required this.id,
    this.familyMemberId,
    this.familyMemberName,
    required this.doctorName,
    required this.hospitalClinic,
    required this.appointmentDate,
    required this.appointmentTime,
    this.purpose,
    this.notes,
    required this.status,
    this.reminderMinutesBefore,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? '',
      familyMemberId: json['familyMemberId'],
      familyMemberName: json['familyMemberName'],
      doctorName: json['doctorName'] ?? '',
      hospitalClinic: json['hospitalClinic'] ?? '',
      appointmentDate: json['appointmentDate'] ?? '',
      appointmentTime: json['appointmentTime'] ?? '',
      purpose: json['purpose'],
      notes: json['notes'],
      status: json['status'] ?? 'UPCOMING',
      reminderMinutesBefore: (json['reminderMinutesBefore'] as num?)?.toInt(),
    );
  }
}
