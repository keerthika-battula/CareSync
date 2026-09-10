import 'package:caresync/core/network/dio_client.dart';
import 'package:caresync/features/medicines/data/models/medicine_models.dart';
import 'package:caresync/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MedicineStateNotifier extends StateNotifier<AsyncValue<List<MedicineModel>>> {
  final Dio _dio;
  final Ref _ref;

  MedicineStateNotifier(this._dio, this._ref) : super(const AsyncValue.loading()) {
    loadMedicines();
  }

  Future<void> loadMedicines() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/medicines');
      final data = response.data['data'] as List<dynamic>? ?? [];
      final list = data.map((json) => MedicineModel.fromJson(json as Map<String, dynamic>)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMedicine({
    required String name,
    String? dosage,
    String? frequency,
    List<String>? scheduledTimes,
    int? currentQuantity,
    int? refillThreshold,
    String? notes,
  }) async {
    try {
      final payload = {
        'name': name.trim(),
        'dosage': dosage?.trim(),
        'frequency': frequency ?? 'ONCE_DAILY',
        'currentQuantity': currentQuantity ?? 0,
        'refillThreshold': refillThreshold ?? 7,
        'notes': notes?.trim(),
        if (scheduledTimes != null && scheduledTimes.isNotEmpty)
          'schedules': scheduledTimes.map((t) => {'scheduledTime': t}).toList(),
      };
      await _dio.post('/medicines', data: payload);
      await loadMedicines();
      _ref.read(reminderProvider.notifier).loadTodayDoses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMedicine({
    required String id,
    required String name,
    String? dosage,
    String? frequency,
    List<String>? scheduledTimes,
    int? currentQuantity,
    int? refillThreshold,
    String? notes,
  }) async {
    try {
      final payload = {
        'name': name.trim(),
        'dosage': dosage?.trim(),
        'frequency': frequency ?? 'ONCE_DAILY',
        'currentQuantity': currentQuantity ?? 0,
        'refillThreshold': refillThreshold ?? 7,
        'notes': notes?.trim(),
        if (scheduledTimes != null && scheduledTimes.isNotEmpty)
          'schedules': scheduledTimes.map((t) => {'scheduledTime': t}).toList(),
      };
      await _dio.put('/medicines/$id', data: payload);
      await loadMedicines();
      _ref.read(reminderProvider.notifier).loadTodayDoses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMedicine(String id) async {
    try {
      await _dio.delete('/medicines/$id');
      await loadMedicines();
      _ref.read(reminderProvider.notifier).loadTodayDoses();
    } catch (e) {
      rethrow;
    }
  }
}

final medicineProvider = StateNotifierProvider<MedicineStateNotifier, AsyncValue<List<MedicineModel>>>((ref) {
  final dio = ref.watch(dioProvider);
  return MedicineStateNotifier(dio, ref);
});
