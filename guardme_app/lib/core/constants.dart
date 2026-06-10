import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'GuardMe';
  static String get baseUrl {
    final env = dotenv.env['API_BASE_URL'];
    if (env != null && env.isNotEmpty) return env;
    return Platform.isAndroid
        ? 'http://10.0.2.2:8080'
        : 'http://localhost:8080';
  }

  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static String get alanVoiceKey => dotenv.env['ALAN_VOICE_KEY'] ?? '';
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
}
