class DashboardStats {
  final int upcomingAppointments;
  final int totalDocuments;
  final int activeMedicines;

  DashboardStats({
    required this.upcomingAppointments,
    required this.totalDocuments,
    required this.activeMedicines,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      upcomingAppointments: json['upcomingAppointments'] ?? 0,
      totalDocuments: json['totalDocuments'] ?? 0,
      activeMedicines: json['activeMedicines'] ?? 0,
    );
  }
}
