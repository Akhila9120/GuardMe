class AppConstants {
  static const String appName = 'GuardMe';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
  static const String alanVoiceKey = String.fromEnvironment(
    'ALAN_VOICE_KEY',
    defaultValue: '',
  );
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
}
