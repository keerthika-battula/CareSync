import 'package:caresync/core/network/dio_client.dart';
import 'package:caresync/features/appointments/data/models/appointment_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppointmentStateNotifier extends StateNotifier<AsyncValue<List<AppointmentModel>>> {
  final Dio _dio;

  AppointmentStateNotifier(this._dio) : super(const AsyncValue.loading()) {
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/appointments');
      final list = response.data['data'] as List<dynamic>? ?? [];
      final appointments = list.map((json) => AppointmentModel.fromJson(json as Map<String, dynamic>)).toList();
      state = AsyncValue.data(appointments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createAppointment({
    required String doctorName,
    String? hospitalClinic,
    required String appointmentDate,
    required String appointmentTime,
    String? purpose,
    String? notes,
    int? reminderMinutesBefore,
    String? familyMemberId,
  }) async {
    try {
      final payload = {
        'doctorName': doctorName.trim(),
        'hospitalClinic': hospitalClinic?.trim(),
        'appointmentDate': appointmentDate,
        'appointmentTime': appointmentTime,
        'purpose': purpose?.trim(),
        'notes': notes?.trim(),
        'reminderMinutesBefore': reminderMinutesBefore ?? 60,
        if (familyMemberId != null && familyMemberId.isNotEmpty) 'familyMemberId': familyMemberId,
      };
      await _dio.post('/appointments', data: payload);
      await loadAppointments();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      await _dio.delete('/appointments/$id');
      await loadAppointments();
    } catch (e) {
      rethrow;
    }
  }
}

final appointmentProvider =
    StateNotifierProvider<AppointmentStateNotifier, AsyncValue<List<AppointmentModel>>>((ref) {
  final dio = ref.watch(dioProvider);
  return AppointmentStateNotifier(dio);
});
