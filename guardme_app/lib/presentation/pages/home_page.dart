import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardme_app/presentation/providers/auth_provider.dart';
import 'package:guardme_app/presentation/providers/emotion_provider.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    ref.listen<EmotionState>(emotionProvider, (_, state) {
      if (!state.isLoading && state.isDistressed != null) {
        _showEmotionResult(context, ref, state.isDistressed!);
      } else if (!state.isLoading && state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFEBEBEB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.apps_rounded, size: 28, color: Colors.black87),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, size: 28, color: Colors.black87),
            onPressed: () => context.go('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF2B2A33),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drawer Top Bar (Close and Menu title)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Menu',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // to offset back button width
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // User Profile Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFFE2DFFF),
                      child: Text(
                        authState.user?.firstName.isNotEmpty == true
                            ? authState.user!.firstName[0].toUpperCase()
                            : 'U',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4C3E9E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        authState.user?.fullName ?? 'User',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Menu List Items
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                title: Text(
                  'Notifications',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/notifications');
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 24),
                title: Text(
                  'Help',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help center is coming soon!')),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Divider(color: Color(0xFF2E6B4A), thickness: 1.5, height: 1),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: const Icon(Icons.people_outline_rounded, color: Colors.white, size: 24),
                title: Text(
                  'Invite a friend',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite link copied to clipboard!')),
                  );
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                title: Text(
                  'Settings',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/settings');
                },
              ),
              const Spacer(),
              // Logout section at the bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                  title: Text(
                    'Log out',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Home,',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                authState.user?.firstName.toUpperCase() ?? 'ADMIN',
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFDCDDE2),
                ),
              ),
              Text(
                'Menu',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildMenuButton(
                    context,
                    icon: Icons.directions_car_outlined,
                    label: 'Start Trip',
                    onTap: () => context.go('/map'),
                  ),
                  _buildMenuButton(
                    context,
                    icon: Icons.assignment_ind_outlined,
                    label: 'Contacts',
                    onTap: () => context.go('/contacts'),
                  ),
                  _buildMenuButton(
                    context,
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Notification',
                    onTap: () => context.go('/notifications'),
                  ),
                  _buildMenuButton(
                    context,
                    icon: Icons.map_outlined,
                    label: 'My Trips',
                    onTap: () => context.go('/trips'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildEmotionCheckButton(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionCheckButton(BuildContext context, WidgetRef ref) {
    final emotionState = ref.watch(emotionProvider);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: emotionState.isLoading
            ? null
            : () => _takeSelfieAndAnalyze(ref),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF6750A4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              children: [
                if (emotionState.isLoading)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                else
                  const Icon(
                    Icons.add_a_photo_outlined,
                    size: 28,
                    color: Colors.white,
                  ),
                const SizedBox(width: 16),
                Text(
                  emotionState.isLoading
                      ? 'ANALYZING...'
                      : 'EMOTION CHECK',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _takeSelfieAndAnalyze(WidgetRef ref) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.camera);
    if (xFile == null) return;

    final file = File(xFile.path);
    ref.read(emotionProvider.notifier).analyzeImage(file);
  }

  void _showEmotionResult(BuildContext context, WidgetRef ref, bool isDistressed) {
    final emotionState = ref.read(emotionProvider);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDistressed ? Icons.warning_rounded : Icons.sentiment_satisfied_rounded,
              size: 64,
              color: isDistressed ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              isDistressed ? 'YES' : 'NO',
              style: GoogleFonts.poppins(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: isDistressed ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDistressed
                  ? 'Signs of distress detected'
                  : 'No signs of distress',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            if (isDistressed && emotionState.calledContactName != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_forwarded_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Calling ${emotionState.calledContactName}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(emotionProvider.notifier).reset();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFDCDDE2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Colors.black87,
                ),
                const SizedBox(height: 16),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
