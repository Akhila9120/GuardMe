import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardme_app/core/dio_client.dart';
import 'package:guardme_app/core/exceptions.dart';
import 'package:guardme_app/domain/entities/contact.dart';
import 'package:guardme_app/domain/repositories/contact_repository_interface.dart';

final contactRepositoryProvider = Provider<ContactRepositoryInterface>((ref) {
  final dio = ref.read(dioClientProvider);
  return ContactRepository(dio: dio);
});

class ContactRepository implements ContactRepositoryInterface {
  final Dio dio;

  ContactRepository({required this.dio});

  @override
  Future<List<Contact>> getContacts() async {
    try {
      final response = await dio.get('/api/contacts');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => Contact.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to load contacts',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Contact> createContact(Contact contact) async {
    try {
      final response = await dio.post('/api/contacts', data: contact.toJson());
      return Contact.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to create contact',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Contact> updateContact(int id, Contact contact) async {
    try {
      final response =
          await dio.put('/api/contacts/$id', data: contact.toJson());
      return Contact.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to update contact',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteContact(int id) async {
    try {
      await dio.delete('/api/contacts/$id');
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to delete contact',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
