import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardme_app/data/repositories/auth_repository.dart';
import 'package:guardme_app/domain/entities/user.dart';

enum AuthStatus { unauthenticated, loading, authenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  Future<void> checkSession() async {
    debugPrint('[Auth] Checking session...');
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final isAuth = await authRepo.isAuthenticated();
      debugPrint('[Auth] isAuthenticated: $isAuth');
      if (isAuth) {
        final user = await authRepo.getAccount();
        debugPrint('[Auth] Session valid, user: ${user.login}');
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        debugPrint('[Auth] No valid session');
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('[Auth] Session check failed: $e');
      state = const AuthState(
        status: AuthStatus.unauthenticated,
      );
    }
  }

  Future<void> login(String login, String password) async {
    debugPrint('[Auth] Attempting login for user: $login');
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final user = await authRepo.login(login, password);
      debugPrint('[Auth] Login successful for user: ${user.login}');
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } on Exception catch (e) {
      debugPrint('[Auth] Login failed: $e');
      state = AuthState(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> register(
    String login,
    String password,
    String firstName,
    String lastName,
    String email,
  ) async {
    debugPrint('[Auth] Attempting registration for user: $login');
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      await authRepo.register(login, password, firstName, lastName, email);
      debugPrint('[Auth] Registration successful, attempting login');
      await this.login(login, password);
    } on Exception catch (e) {
      debugPrint('[Auth] Registration failed: $e');
      state = AuthState(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    debugPrint('[Auth] Logging out');
    final authRepo = _ref.read(authRepositoryProvider);
    await authRepo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
