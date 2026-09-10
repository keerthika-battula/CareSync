import 'package:intl/intl.dart';

class MedicineScheduleModel {
  final String? id;
  final String? frequency;
  final String? scheduledTime;
  final List<String> scheduledTimes;
  final List<int>? daysOfWeek;

  MedicineScheduleModel({
    this.id,
    this.frequency,
    this.scheduledTime,
    this.scheduledTimes = const [],
    this.daysOfWeek,
  });

  factory MedicineScheduleModel.fromJson(Map<String, dynamic> json) {
    List<String> times = [];
    if (json['scheduledTimes'] is List) {
      times = (json['scheduledTimes'] as List).map((e) => e.toString()).toList();
    } else if (json['scheduledTime'] != null) {
      times = [json['scheduledTime'].toString()];
    }

    return MedicineScheduleModel(
      id: json['id']?.toString(),
      frequency: json['frequency']?.toString(),
      scheduledTime: json['scheduledTime']?.toString(),
      scheduledTimes: times,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
    );
  }
}

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
  final List<MedicineScheduleModel> schedules;

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
    this.schedules = const [],
  });

  bool get isLowStock => currentQuantity <= refillThreshold;

  /// Returns list of formatted schedule times e.g. ["8:00 AM", "8:00 PM"]
  List<String> get formattedScheduleTimes {
    final times = <String>[];
    for (final s in schedules) {
      for (final t in s.scheduledTimes) {
        final formatted = formatTimeString(t);
        if (formatted.isNotEmpty && !times.contains(formatted)) {
          times.add(formatted);
        }
      }
      if (s.scheduledTime != null && s.scheduledTime!.isNotEmpty) {
        final formatted = formatTimeString(s.scheduledTime!);
        if (formatted.isNotEmpty && !times.contains(formatted)) {
          times.add(formatted);
        }
      }
    }
    return times;
  }

  /// Returns single summary string e.g. "8:00 AM" or "8:00 AM • 8:00 PM"
  String get scheduleDisplaySummary {
    final list = formattedScheduleTimes;
    if (list.isEmpty) {
      return '';
    }
    return list.join(' • ');
  }

  static String formatTimeString(String raw) {
    try {
      if (raw.contains('T')) {
        final dt = DateTime.parse(raw);
        return DateFormat('h:mm a').format(dt);
      }
      final parts = raw.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final dt = DateTime(2026, 1, 1, hour, minute);
        return DateFormat('h:mm a').format(dt);
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    List<MedicineScheduleModel> schedules = [];
    if (json['schedules'] is List) {
      schedules = (json['schedules'] as List)
          .map((s) => MedicineScheduleModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }

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
      schedules: schedules,
    );
  }
}
