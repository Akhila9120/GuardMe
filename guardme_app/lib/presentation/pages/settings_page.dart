import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardme_app/presentation/providers/settings_provider.dart';
import 'package:guardme_app/presentation/widgets/my_button.dart';
import 'package:guardme_app/presentation/widgets/my_text_field.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      _ipController.text = settings.ip;
      _portController.text = settings.port.toString();
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final settings = ref.read(settingsProvider);
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;

    await ref.read(settingsProvider.notifier).save(
          ip: ip,
          port: port,
          useDefault: settings.useDefault,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings saved!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Backend: http://$ip:$port',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Restart the app to apply changes',
                style: GoogleFonts.poppins(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF6750A4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;
    final url = 'http://$ip:$port';
    await ref.read(settingsProvider.notifier).testConnection(url);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEBEBEB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: 'Backend Server',
                subtitle: 'Configure the API server connection',
                children: [
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: Text(
                      'Use default address',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      settings.useDefault
                          ? 'Using platform default'
                          : 'Using custom address',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    value: settings.useDefault,
                    activeTrackColor: const Color(0xFF6750A4).withValues(alpha: 0.5),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).setUseDefault(value);
                      if (value) {
                        _ipController.clear();
                        _portController.text = '8080';
                      }
                    },
                  ),
                  const Divider(height: 24),
                  if (!settings.useDefault) ...[
                    Text(
                      'Server IP Address',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    MyTextField(
                      controller: _ipController,
                      hintText: 'e.g. 192.168.1.100',
                      prefixIcon: Icons.dns_outlined,
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'IP address is required';
                        }
                        final ipRegex = RegExp(
                          r'^(\d{1,3}\.){3}\d{1,3}$|^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9](\.[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])*$|^localhost$',
                        );
                        if (!ipRegex.hasMatch(value.trim())) {
                          return 'Enter a valid IP or hostname';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Port',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    MyTextField(
                      controller: _portController,
                      hintText: '8080',
                      prefixIcon: Icons.tag_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Port is required';
                        }
                        final port = int.tryParse(value.trim());
                        if (port == null || port < 1 || port > 65535) {
                          return 'Enter a valid port (1-65535)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Full URL: http://${_ipController.text.isEmpty ? "<ip>" : _ipController.text}:${_portController.text.isEmpty ? "<port>" : _portController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6750A4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2DFFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF6750A4),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Default mode uses the address from your .env file or platform defaults (10.0.2.2:8080 for Android emulator, localhost:8080 otherwise).',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF4C3E9E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionCard(
                title: 'Connection Test',
                subtitle: 'Verify the backend server is reachable',
                children: [
                  const SizedBox(height: 16),
                  MyButton(
                    text: settings.isTesting ? 'Testing...' : 'Test Connection',
                    onPressed: settings.isTesting ? null : _testConnection,
                    isLoading: settings.isTesting,
                    color: const Color(0xFF2E6B4A),
                  ),
                  if (settings.testResult != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: settings.testResult!.contains('Cannot connect') ||
                                settings.testResult!.contains('failed')
                            ? Colors.red[50]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: settings.testResult!.contains('Cannot connect') ||
                                  settings.testResult!.contains('failed')
                              ? Colors.red[200]!
                              : Colors.green[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            settings.testResult!.contains('Cannot connect') ||
                                    settings.testResult!.contains('failed')
                                ? Icons.error_outline_rounded
                                : Icons.check_circle_outline_rounded,
                            color: settings.testResult!.contains('Cannot connect') ||
                                    settings.testResult!.contains('failed')
                                ? Colors.red[700]
                                : Colors.green[700],
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              settings.testResult!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: settings.testResult!.contains('Cannot connect') ||
                                        settings.testResult!.contains('failed')
                                    ? Colors.red[700]
                                    : Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              if (!settings.useDefault)
                MyButton(
                  text: 'Save Settings',
                  onPressed: settings.isLoading ? null : _save,
                  isLoading: settings.isLoading,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
