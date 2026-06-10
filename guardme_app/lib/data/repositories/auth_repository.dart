import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guardme_app/core/dio_client.dart';
import 'package:guardme_app/core/exceptions.dart';
import 'package:guardme_app/domain/entities/user.dart';
import 'package:guardme_app/domain/repositories/auth_repository_interface.dart';

final authRepositoryProvider = Provider<AuthRepositoryInterface>((ref) {
  final dio = ref.read(dioClientProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthRepository(dio: dio, storage: storage);
});

class AuthRepository implements AuthRepositoryInterface {
  final Dio dio;
  final FlutterSecureStorage storage;

  AuthRepository({required this.dio, required this.storage});

  @override
  Future<User> login(String login, String password) async {
    try {
      final authResponse = await dio.post(
        '/api/authenticate',
        data: {'username': login, 'password': password},
      );
      if (authResponse.statusCode != 200) {
        throw AuthException(message: 'Invalid credentials');
      }
      final token = authResponse.data['id_token'] as String?;
      if (token == null || token.isEmpty) {
        throw AuthException(message: 'No token received');
      }
      await storage.write(key: 'jwt_token', value: token);

      final accountResponse = await dio.get('/api/account');
      final user = User.fromJson(accountResponse.data as Map<String, dynamic>);
      return User(
        id: user.id,
        login: user.login,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        authorities: user.authorities,
        token: token,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(message: 'Connection timed out. Please try again.');
      }
      if (e.response?.statusCode == 401) {
        throw AuthException(message: 'Invalid username or password');
      }
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Login failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> register(
    String login,
    String password,
    String firstName,
    String lastName,
    String email,
  ) async {
    try {
      final response = await dio.post('/api/register', data: {
        'login': login,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      });
      if (response.statusCode != 201) {
        throw ServerException(message: 'Registration failed');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(message: 'Connection timed out. Please try again.');
      }
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data as Map<String, dynamic>?;
        final message = errors?['message'] ?? 'Invalid registration data';
        throw ServerException(message: message);
      }
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Registration failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<User> getAccount() async {
    try {
      final response = await dio.get('/api/account');
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException(message: 'Session expired. Please login again.');
      }
      throw ServerException(message: 'Failed to get account info');
    }
  }

  @override
  Future<void> logout() async {
    await storage.deleteAll();
  }

  @override
  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }
}
