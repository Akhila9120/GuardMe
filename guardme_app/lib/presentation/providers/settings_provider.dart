import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final String ip;
  final int port;
  final bool useDefault;
  final bool isLoading;
  final bool isTesting;
  final String? testResult;
  final bool isInitialized;

  const SettingsState({
    this.ip = '',
    this.port = 8080,
    this.useDefault = true,
    this.isLoading = false,
    this.isTesting = false,
    this.testResult,
    this.isInitialized = false,
  });

  String get baseUrl => 'http://$ip:$port';

  SettingsState copyWith({
    String? ip,
    int? port,
    bool? useDefault,
    bool? isLoading,
    bool? isTesting,
    String? testResult,
    bool? isInitialized,
  }) {
    return SettingsState(
      ip: ip ?? this.ip,
      port: port ?? this.port,
      useDefault: useDefault ?? this.useDefault,
      isLoading: isLoading ?? this.isLoading,
      isTesting: isTesting ?? this.isTesting,
      testResult: testResult,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _keyIp = 'settings_backend_ip';
  static const String _keyPort = 'settings_backend_port';
  static const String _keyUseDefault = 'settings_use_default';
  static const int _defaultPort = 8080;

  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final useDefault = prefs.getBool(_keyUseDefault) ?? true;
      final ip = prefs.getString(_keyIp) ?? '';
      final port = prefs.getInt(_keyPort) ?? _defaultPort;
      state = state.copyWith(
        ip: ip,
        port: port,
        useDefault: useDefault,
        isInitialized: true,
      );
    } catch (e) {
      debugPrint('[Settings] Error loading: $e');
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> save({required String ip, required int port, required bool useDefault}) async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyIp, ip);
      await prefs.setInt(_keyPort, port);
      await prefs.setBool(_keyUseDefault, useDefault);
      state = state.copyWith(
        ip: ip,
        port: port,
        useDefault: useDefault,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[Settings] Error saving: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void setIp(String ip) {
    state = state.copyWith(ip: ip);
  }

  void setPort(int port) {
    state = state.copyWith(port: port);
  }

  void setUseDefault(bool value) {
    state = state.copyWith(useDefault: value);
  }

  void clearTestResult() {
    state = state.copyWith(testResult: null);
  }

  Future<bool> testConnection(String url) async {
    state = state.copyWith(isTesting: true, testResult: null);
    try {
      final dio = Dio(BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      // Test root endpoint - any response means server is reachable
      await dio.get('/');
      state = state.copyWith(
        isTesting: false,
        testResult: 'Connected! Server is reachable',
      );
      return true;
    } on DioException catch (e) {
      if (e.response != null) {
        // Server responded (even with error) - it's reachable
        state = state.copyWith(
          isTesting: false,
          testResult: 'Connected! Server is reachable (status: ${e.response!.statusCode})',
        );
        return true;
      }
      // No response - server unreachable
      state = state.copyWith(
        isTesting: false,
        testResult: 'Cannot connect: ${e.message ?? 'Server unreachable'}',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isTesting: false,
        testResult: 'Connection failed: $e',
      );
      return false;
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
