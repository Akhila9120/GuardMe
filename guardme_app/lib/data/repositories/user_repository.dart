import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardme_app/core/dio_client.dart';
import 'package:guardme_app/core/exceptions.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dio = ref.read(dioClientProvider);
  return UserRepository(dio: dio);
});

class UserRepository {
  final Dio dio;

  UserRepository({required this.dio});

  Future<Map<String, dynamic>> getAppUser() async {
    try {
      final response = await dio.get('/api/account');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to load user profile',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await dio.put('/api/account', data: data);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to update profile',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
