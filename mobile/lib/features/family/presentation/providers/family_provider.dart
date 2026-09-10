import 'package:caresync/core/network/dio_client.dart';
import 'package:caresync/features/family/data/models/family_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FamilyStateNotifier extends StateNotifier<AsyncValue<List<FamilyMemberModel>>> {
  final Dio _dio;

  FamilyStateNotifier(this._dio) : super(const AsyncValue.loading()) {
    loadFamilyMembers();
  }

  Future<void> loadFamilyMembers() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/family');
      final list = response.data['data'] as List<dynamic>? ?? [];
      final members = list.map((json) => FamilyMemberModel.fromJson(json as Map<String, dynamic>)).toList();
      state = AsyncValue.data(members);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFamilyMember({
    required String name,
    required String relationship,
    String? dateOfBirth,
  }) async {
    try {
      final payload = {
        'name': name.trim(),
        'relationship': relationship.trim(),
        if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'dateOfBirth': dateOfBirth,
      };
      await _dio.post('/family', data: payload);
      await loadFamilyMembers();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFamilyMember(String id) async {
    try {
      await _dio.delete('/family/$id');
      await loadFamilyMembers();
    } catch (e) {
      rethrow;
    }
  }
}

final familyProvider = StateNotifierProvider<FamilyStateNotifier, AsyncValue<List<FamilyMemberModel>>>((ref) {
  final dio = ref.watch(dioProvider);
  return FamilyStateNotifier(dio);
});
