import 'package:guardme_app/domain/entities/user.dart';

abstract class AuthRepositoryInterface {
  Future<User> login(String login, String password);
  Future<void> register(
    String login,
    String password,
    String firstName,
    String lastName,
    String email,
  );
  Future<User> getAccount();
  Future<void> logout();
  Future<String?> getToken();
  Future<bool> isAuthenticated();
}
