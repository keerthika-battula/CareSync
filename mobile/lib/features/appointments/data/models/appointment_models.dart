class AppointmentModel {
  final String id;
  final String doctorName;
  final String hospitalClinic;
  final String appointmentDate;
  final String appointmentTime;
  final String status;

  AppointmentModel({
    required this.id,
    required this.doctorName,
    required this.hospitalClinic,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      doctorName: json['doctorName'] ?? '',
      hospitalClinic: json['hospitalClinic'] ?? '',
      appointmentDate: json['appointmentDate'],
      appointmentTime: json['appointmentTime'],
      status: json['status'],
    );
  }
}
