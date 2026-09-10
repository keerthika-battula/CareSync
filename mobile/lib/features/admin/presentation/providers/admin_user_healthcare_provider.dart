import 'package:caresync/core/network/dio_client.dart';
import 'package:caresync/core/utils/file_download_helper.dart';
import 'package:caresync/features/appointments/data/models/appointment_models.dart';
import 'package:caresync/features/documents/data/models/document_models.dart';
import 'package:caresync/features/family/data/models/family_models.dart';
import 'package:caresync/features/medicines/data/models/medicine_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminUserMedicinesProvider =
    FutureProvider.family<List<MedicineModel>, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/v1/admin/users/$userId/medicines');
  final list = response.data['data'] as List<dynamic>? ?? [];
  return list.map((json) => MedicineModel.fromJson(json as Map<String, dynamic>)).toList();
});

final adminUserDocumentsProvider =
    FutureProvider.family<List<HealthcareDocumentModel>, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/v1/admin/users/$userId/documents');
  final list = response.data['data'] as List<dynamic>? ?? [];
  return list.map((json) => HealthcareDocumentModel.fromJson(json as Map<String, dynamic>)).toList();
});

final adminUserFamilyProvider =
    FutureProvider.family<List<FamilyMemberModel>, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/v1/admin/users/$userId/family');
  final list = response.data['data'] as List<dynamic>? ?? [];
  return list.map((json) => FamilyMemberModel.fromJson(json as Map<String, dynamic>)).toList();
});

final adminUserAppointmentsProvider =
    FutureProvider.family<List<AppointmentModel>, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/v1/admin/users/$userId/appointments');
  final list = response.data['data'] as List<dynamic>? ?? [];
  return list.map((json) => AppointmentModel.fromJson(json as Map<String, dynamic>)).toList();
});

Future<void> downloadAdminUserDocument(
  WidgetRef ref,
  String userId,
  HealthcareDocumentModel doc, {
  bool openInNewTab = false,
}) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(
    '/v1/admin/users/$userId/documents/${doc.id}/download',
    options: Options(responseType: ResponseType.bytes),
  );
  final bytes = response.data as List<int>;
  if (openInNewTab) {
    openBytesInBrowser(bytes, mimeType: doc.mimeType);
  } else {
    downloadBytesInBrowser(bytes, doc.fileName, mimeType: doc.mimeType);
  }
}
