import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardme_app/presentation/providers/chat_provider.dart';

class ChatInput extends ConsumerStatefulWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttachImage;

  const ChatInput({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.onSend,
    required this.onAttachImage,
  });

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _waveController.dispose();
    widget.textController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  Future<void> _startRecording() async {
    await ref.read(chatProvider.notifier).startRecording();
  }

  Future<void> _stopAndSendRecording() async {
    final path = await ref.read(chatProvider.notifier).stopRecording();
    if (path != null) {
      await ref.read(chatProvider.notifier).sendVoice(path);
    }
  }

  void _cancelRecording() {
    ref.read(chatProvider.notifier).cancelRecording();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isRecording = chatState.isRecording;
    final recordingDuration = chatState.recordingDuration;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 6),
          child: isRecording
              ? _buildRecordingOverlay(recordingDuration)
              : _buildNormalInput(),
        ),
      ),
    );
  }

  Widget _buildNormalInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: IconButton(
            icon: Icon(Icons.add_circle_outline_rounded,
                color: Colors.grey[600], size: 28),
            onPressed: widget.onAttachImage,
            tooltip: 'Attach image',
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: widget.textController,
              focusNode: widget.focusNode,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Message Guard Intelligence...',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
              ),
              onSubmitted: _hasText ? (_) => widget.onSend() : null,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _hasText ? _buildSendButton() : _buildMicButton(),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF6750A4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        onPressed: widget.onSend,
        tooltip: 'Send',
      ),
    );
  }

  Widget _buildMicButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.mic_rounded, color: Colors.black87, size: 22),
        onPressed: _startRecording,
        tooltip: 'Record voice',
      ),
    );
  }

  Widget _buildRecordingOverlay(Duration duration) {
    final formatted =
        '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.red, size: 26),
            onPressed: _cancelRecording,
            tooltip: 'Cancel recording',
          ),
          const Spacer(),
          SizedBox(
            height: 32,
            width: 100,
            child: AnimatedBuilder(
              listenable: _waveController,
              builder: (context, child) => CustomPaint(
                painter: _WaveformPainter(
                  progress: _waveController.value,
                  color: const Color(0xFF6750A4),
                ),
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Colors.red.shade400, size: 10),
              const SizedBox(width: 6),
              Text(
                formatted,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF6750A4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 22),
              onPressed: _stopAndSendRecording,
              tooltip: 'Send recording',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WaveformPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const barCount = 12;
    final spacing = size.width / barCount;
    const baseHeight = 6.0;
    final maxHeight = size.height - 4;

    for (var i = 0; i < barCount; i++) {
      final x = spacing / 2 + i * spacing;
      final barProgress = ((i / barCount) + progress) % 1.0;
      final height =
          baseHeight + (maxHeight - baseHeight) * _barCurve(barProgress);
      final y = (size.height - height) / 2;

      canvas.drawLine(Offset(x, y), Offset(x, y + height), paint);
    }
  }

  double _barCurve(double t) {
    return (t * (1 - t) * 4).clamp(0.1, 1.0);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
