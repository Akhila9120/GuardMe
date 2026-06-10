import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'GuardMe';
  
  // Custom backend URL from settings (loaded at app startup)
  static String? _customBaseUrl;
  
  static void setCustomBaseUrl(String? url) {
    _customBaseUrl = url;
  }
  
  static String get baseUrl {
    // Use custom URL if set
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    
    // Fall back to .env
    final env = dotenv.env['API_BASE_URL'];
    if (env != null && env.isNotEmpty) return env;
    
    // Fall back to platform default
    return Platform.isAndroid
        ? 'http://10.0.2.2:8080'
        : 'http://localhost:8080';
  }

  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static String get alanVoiceKey => dotenv.env['ALAN_VOICE_KEY'] ?? '';
  static String get opencodeGoApiKey => dotenv.env['OPENCODE_GO_API_KEY'] ?? '';
  static String get anthropicBaseUrl =>
      dotenv.env['ANTHROPIC_BASE_URL'] ?? 'https://opencode.ai/zen/go';
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
}
