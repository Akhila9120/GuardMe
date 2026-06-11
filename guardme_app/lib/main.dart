import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twilio_voice_sms/twilio_voice_sms.dart';
import 'app.dart';
import 'core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Initialize Twilio for direct SMS sending
  FlutterTwilio.instance.init(
    accountSid: dotenv.env['TWILIO_ACCOUNT_SID'] ?? '',
    authToken: dotenv.env['TWILIO_AUTH_TOKEN'] ?? '',
    twilioNumber: dotenv.env['TWILIO_FROM_NUMBER'] ?? '',
  );

  // Load custom backend URL from settings (if any)
  final prefs = await SharedPreferences.getInstance();
  final useDefault = prefs.getBool('settings_use_default') ?? true;
  if (!useDefault) {
    final ip = prefs.getString('settings_backend_ip') ?? '';
    final port = prefs.getInt('settings_backend_port') ?? 8080;
    if (ip.isNotEmpty) {
      AppConstants.setCustomBaseUrl('http://$ip:$port');
    }
  }

  runApp(const ProviderScope(child: GuardMeApp()));
}
