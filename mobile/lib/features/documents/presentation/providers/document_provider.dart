import 'dart:typed_data';
import 'package:caresync/core/network/dio_client.dart';
import 'package:caresync/core/utils/file_download_helper.dart';
import 'package:caresync/features/documents/data/models/document_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DocumentStateNotifier extends StateNotifier<AsyncValue<List<HealthcareDocumentModel>>> {
  final Dio _dio;

  DocumentStateNotifier(this._dio) : super(const AsyncValue.loading()) {
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/documents');
      final data = response.data['data'] as List<dynamic>? ?? [];
      final list = data.map((json) => HealthcareDocumentModel.fromJson(json as Map<String, dynamic>)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadDocument({
    required Uint8List bytes,
    required String fileName,
    required String title,
    required String documentType,
    String? description,
    String? familyMemberId,
  }) async {
    try {
      final multipart = MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      );

      final formData = FormData.fromMap({
        'file': multipart,
        'title': title.trim(),
        'documentType': documentType,
        if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
        if (familyMemberId != null && familyMemberId.isNotEmpty) 'familyMemberId': familyMemberId,
      });

      await _dio.post('/documents', data: formData);
      await loadDocuments();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> downloadDocument(HealthcareDocumentModel doc, {bool openInNewTab = false}) async {
    try {
      final response = await _dio.get(
        '/documents/${doc.id}/download',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data as List<int>;
      if (openInNewTab) {
        openBytesInBrowser(bytes, mimeType: doc.mimeType);
      } else {
        downloadBytesInBrowser(bytes, doc.fileName, mimeType: doc.mimeType);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _dio.delete('/documents/$id');
      await loadDocuments();
    } catch (e) {
      rethrow;
    }
  }
}

final documentProvider = StateNotifierProvider<DocumentStateNotifier, AsyncValue<List<HealthcareDocumentModel>>>((ref) {
  final dio = ref.watch(dioProvider);
  return DocumentStateNotifier(dio);
});
