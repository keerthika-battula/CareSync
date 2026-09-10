import 'package:caresync/core/network/dio_client.dart';
import 'package:caresync/features/medicines/data/models/medicine_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MedicineStateNotifier extends StateNotifier<AsyncValue<List<MedicineModel>>> {
  final Dio _dio;

  MedicineStateNotifier(this._dio) : super(const AsyncValue.loading()) {
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
    int? currentQuantity,
    int? refillThreshold,
    String? notes,
  }) async {
    try {
      final payload = {
        'name': name.trim(),
        'dosage': dosage?.trim(),
        'currentQuantity': currentQuantity ?? 0,
        'refillThreshold': refillThreshold ?? 7,
        'notes': notes?.trim(),
      };
      await _dio.post('/medicines', data: payload);
      await loadMedicines();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMedicine({
    required String id,
    required String name,
    String? dosage,
    int? currentQuantity,
    int? refillThreshold,
    String? notes,
  }) async {
    try {
      final payload = {
        'name': name.trim(),
        'dosage': dosage?.trim(),
        'currentQuantity': currentQuantity ?? 0,
        'refillThreshold': refillThreshold ?? 7,
        'notes': notes?.trim(),
      };
      await _dio.put('/medicines/$id', data: payload);
      await loadMedicines();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMedicine(String id) async {
    try {
      await _dio.delete('/medicines/$id');
      await loadMedicines();
    } catch (e) {
      rethrow;
    }
  }
}

final medicineProvider = StateNotifierProvider<MedicineStateNotifier, AsyncValue<List<MedicineModel>>>((ref) {
  final dio = ref.watch(dioProvider);
  return MedicineStateNotifier(dio);
});
