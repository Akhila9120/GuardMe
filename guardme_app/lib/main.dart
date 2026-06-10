import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
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
