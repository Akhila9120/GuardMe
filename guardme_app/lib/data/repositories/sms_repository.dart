import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardme_app/core/dio_client.dart';
import 'package:guardme_app/core/exceptions.dart';

final smsRepositoryProvider = Provider<SmsRepository>((ref) {
  final dio = ref.read(dioClientProvider);
  return SmsRepository(dio: dio);
});

class SmsRepository {
  final Dio dio;

  SmsRepository({required this.dio});

  Future<void> sendSmsToOne(int contactId, String message) async {
    try {
      await dio.post('/api/sms/send', data: {
        'contactId': contactId,
        'message': message,
      });
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to send SMS',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> sendSmsToAll(String message) async {
    try {
      await dio.post('/api/sms/send-all', data: {
        'message': message,
      });
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to send SMS to all contacts',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> sendWhatsAppToOne(int contactId, String message) async {
    try {
      await dio.post('/api/sms/whatsapp', data: {
        'contactId': contactId,
        'message': message,
      });
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to send WhatsApp message',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> sendWhatsAppToAll(String message) async {
    try {
      await dio.post('/api/sms/whatsapp-all', data: {
        'message': message,
      });
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to send WhatsApp to all contacts',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
