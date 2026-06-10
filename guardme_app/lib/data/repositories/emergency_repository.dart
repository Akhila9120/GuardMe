import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardme_app/core/dio_client.dart';
import 'package:guardme_app/core/exceptions.dart';
import 'package:guardme_app/domain/entities/emergency_alert.dart';

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  final dio = ref.read(dioClientProvider);
  return EmergencyRepository(dio: dio);
});

class EmergencyRepository {
  final Dio dio;

  EmergencyRepository({required this.dio});

  Future<List<EmergencyAlert>> getAlerts() async {
    try {
      final response = await dio.get('/api/alerts');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => EmergencyAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to load alerts',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<EmergencyAlert> createAlert(EmergencyAlert alert) async {
    try {
      final response = await dio.post('/api/alerts', data: alert.toJson());
      return EmergencyAlert.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to create alert',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<EmergencyAlert> resolveAlert(int id) async {
    try {
      final response = await dio.put('/api/alerts/$id/resolve');
      return EmergencyAlert.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to resolve alert',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
