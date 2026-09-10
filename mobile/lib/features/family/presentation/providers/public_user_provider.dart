import 'package:caresync/core/network/dio_client.dart';
import 'package:caresync/features/family/data/models/public_user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final publicUserNamesProvider = FutureProvider<List<PublicUserName>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/v1/users/names');
  final rawList = response.data['data'] as List<dynamic>? ?? [];
  return rawList
      .map((item) => PublicUserName.fromJson(item as Map<String, dynamic>))
      .toList();
});
