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
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final isAuth = await authRepo.isAuthenticated();
      if (isAuth) {
        final user = await authRepo.getAccount();
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
      );
    }
  }

  Future<void> login(String login, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final user = await authRepo.login(login, password);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } on Exception catch (e) {
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
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      await authRepo.register(login, password, firstName, lastName, email);
      await this.login(login, password);
    } on Exception catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    final authRepo = _ref.read(authRepositoryProvider);
    await authRepo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
