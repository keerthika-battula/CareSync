import 'package:caresync/core/network/dio_client.dart';
import 'package:caresync/features/medicines/presentation/providers/medicine_provider.dart';
import 'package:caresync/features/reminders/data/models/reminder_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReminderStateNotifier extends StateNotifier<AsyncValue<List<ReminderOccurrenceModel>>> {
  final Dio _dio;
  final Ref _ref;

  ReminderStateNotifier(this._dio, this._ref) : super(const AsyncValue.loading()) {
    loadTodayDoses();
  }

  Future<void> loadTodayDoses() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/reminders/today');
      final data = response.data['data'] as List<dynamic>? ?? [];
      final list = data.map((json) => ReminderOccurrenceModel.fromJson(json as Map<String, dynamic>)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markTaken(String occurrenceId) async {
    try {
      final response = await _dio.post('/reminders/$occurrenceId/taken');
      if (response.data['data'] != null) {
        final updated = ReminderOccurrenceModel.fromJson(response.data['data'] as Map<String, dynamic>);
        _updateLocalOccurrence(updated);
      }
      _ref.read(medicineProvider.notifier).loadMedicines();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markSkipped(String occurrenceId) async {
    try {
      final response = await _dio.post('/reminders/$occurrenceId/skip');
      if (response.data['data'] != null) {
        final updated = ReminderOccurrenceModel.fromJson(response.data['data'] as Map<String, dynamic>);
        _updateLocalOccurrence(updated);
      }
      _ref.read(medicineProvider.notifier).loadMedicines();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> snooze(String occurrenceId, int minutes) async {
    try {
      final response = await _dio.post(
        '/reminders/$occurrenceId/snooze',
        data: {'minutes': minutes},
      );
      if (response.data['data'] != null) {
        final updated = ReminderOccurrenceModel.fromJson(response.data['data'] as Map<String, dynamic>);
        _updateLocalOccurrence(updated);
      }
      _ref.read(medicineProvider.notifier).loadMedicines();
    } catch (e) {
      rethrow;
    }
  }

  void _updateLocalOccurrence(ReminderOccurrenceModel updated) {
    state.whenData((currentList) {
      final newList = currentList.map((occ) {
        return occ.id == updated.id ? updated : occ;
      }).toList();
      state = AsyncValue.data(newList);
    });
  }
}

final reminderProvider = StateNotifierProvider<ReminderStateNotifier, AsyncValue<List<ReminderOccurrenceModel>>>((ref) {
  final dio = ref.watch(dioProvider);
  return ReminderStateNotifier(dio, ref);
});
