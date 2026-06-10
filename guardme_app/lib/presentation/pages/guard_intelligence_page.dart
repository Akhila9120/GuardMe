import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardme_app/presentation/providers/chat_provider.dart';
import 'package:guardme_app/presentation/widgets/chat_bubble.dart';
import 'package:guardme_app/presentation/widgets/chat_input.dart';
import 'package:image_picker/image_picker.dart';

class GuardIntelligencePage extends ConsumerStatefulWidget {
  const GuardIntelligencePage({super.key});

  @override
  ConsumerState<GuardIntelligencePage> createState() =>
      _GuardIntelligencePageState();
}

class _GuardIntelligencePageState
    extends ConsumerState<GuardIntelligencePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendText() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(chatProvider.notifier).sendText(text);
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _imageSourceButton(ctx, Icons.camera_alt_outlined, 'Camera',
                  ImageSource.camera),
              _imageSourceButton(ctx, Icons.photo_library_outlined, 'Gallery',
                  ImageSource.gallery),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (xFile == null) return;

    ref.read(chatProvider.notifier).sendImage(File(xFile.path));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    ref.listen<ChatState>(chatProvider, (_, state) {
      if (state.isDistressed == true) {
        _showDistressAlert(state);
      }
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
        ref.read(chatProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFEBEBEB),
      appBar: _buildAppBar(chatState),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    reverse: true,
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[
                          chatState.messages.length - 1 - index];
                      return ChatBubble(message: message);
                    },
                  ),
          ),
          ChatInput(
            textController: _textController,
            focusNode: _focusNode,
            onSend: _sendText,
            onAttachImage: _pickImage,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatState chatState) {
    return AppBar(
      backgroundColor: const Color(0xFFEBEBEB),
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
        onPressed: () => context.go('/home'),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guard Intelligence',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              if (chatState.isLoading)
                Text(
                  'Thinking...',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (chatState.messages.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.black54),
            tooltip: 'Clear chat',
            onPressed: () => _showClearDialog(),
          ),
      ],
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear chat?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content:
            Text('This will delete all messages.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
              Navigator.of(ctx).pop();
            },
            child:
                Text('Clear', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _imageSourceButton(
      BuildContext ctx, IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => Navigator.of(ctx).pop(source),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF6750A4).withValues(alpha: 0.15),
            child: Icon(icon, size: 32, color: const Color(0xFF6750A4)),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
        ],
      ),
    );
  }

  void _showDistressAlert(ChatState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_rounded, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'DI STRESS DETECTED',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Signs of distress detected in conversation',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.calledContactName != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_forwarded_rounded,
                      color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Calling ${state.calledContactName}',
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
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('I\'m OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final suggestions = [
      'Analyze my surroundings',
      'Check if I\'m safe',
      'How do I stay safe at night?',
      'Emergency tips',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6750A4).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 40,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Guard Intelligence',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'I\'m your AI safety assistant.\nHow can I help you?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions.map((s) {
                return ActionChip(
                  label: Text(s, style: GoogleFonts.poppins(fontSize: 12)),
                  onPressed: () {
                    ref.read(chatProvider.notifier).sendText(s);
                    _scrollToBottom();
                  },
                  backgroundColor:
                      const Color(0xFF6750A4).withValues(alpha: 0.1),
                  side: BorderSide(
                    color: const Color(0xFF6750A4).withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
