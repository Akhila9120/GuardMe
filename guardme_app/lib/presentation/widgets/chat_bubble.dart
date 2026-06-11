import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardme_app/domain/entities/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isToolStatus) return _ToolStatusBubble(message: message);

    final isUser = message.role == 'user';
    final bubbleColor =
        isUser ? const Color(0xFF6750A4) : Colors.white;
    final textColor = isUser ? Colors.white : Colors.black87;

    if (message.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(Colors.black26, 0),
                  const SizedBox(width: 4),
                  _dot(Colors.black26, 150),
                  const SizedBox(width: 4),
                  _dot(Colors.black26, 300),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6750A4).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded,
                  size: 18, color: Color(0xFF6750A4)),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.imagePath != null)
                      _ImageBubble(imagePath: message.imagePath!),
                    if (message.audioPath != null)
                      _AudioBubble(audioPath: message.audioPath!, isUser: isUser),
                    if (message.text != null && message.text!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: (message.imagePath != null ||
                                  message.audioPath != null)
                              ? 8
                              : 0,
                        ),
                        child: isUser
                            ? Text(
                                message.text!,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: textColor,
                                  height: 1.4,
                                ),
                              )
                            : MarkdownBody(
                                data: message.text!,
                                styleSheet: MarkdownStyleSheet(
                                  p: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: textColor,
                                    height: 1.4,
                                  ),
                                  h1: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  h2: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  h3: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                  strong: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  em: GoogleFonts.poppins(
                                    fontStyle: FontStyle.italic,
                                    color: textColor,
                                  ),
                                  code: GoogleFonts.jetBrainsMono(
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                  codeblockDecoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  codeblockPadding: const EdgeInsets.all(12),
                                  blockquoteDecoration: BoxDecoration(
                                    border: const Border(
                                      left: BorderSide(
                                        color: Color(0xFF6750A4),
                                        width: 3,
                                      ),
                                    ),
                                    color: const Color(0xFF6750A4)
                                        .withValues(alpha: 0.05),
                                  ),
                                  blockquotePadding: const EdgeInsets.fromLTRB(
                                      12, 4, 12, 4),
                                  listBullet: TextStyle(color: textColor),
                                  horizontalRuleDecoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  a: GoogleFonts.poppins(
                                    color: const Color(0xFF6750A4),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.formattedTime,
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser
                                ? Colors.white70
                                : Colors.black38,
                          ),
                        ),
                        if (isUser)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: Colors.white60,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color, int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final String imagePath;

  const _ImageBubble({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () => _showFullImage(context),
        child: Image.file(
          File(imagePath),
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 100,
            color: Colors.grey[200],
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(imagePath)),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioBubble extends StatefulWidget {
  final String audioPath;
  final bool isUser;

  const _AudioBubble({required this.audioPath, required this.isUser});

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  final AudioPlayer _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      try {
        if (!_isInitialized) {
          await _player.setSource(DeviceFileSource(widget.audioPath));
          _isInitialized = true;
        }
        await _player.resume();
      } catch (e) {
        debugPrint('[Audio] Error playing: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
    final remaining = _duration - _position;

    final buttonBgColor = widget.isUser
        ? Colors.white.withValues(alpha: 0.25)
        : const Color(0xFF6750A4).withValues(alpha: 0.15);
    final iconColor = widget.isUser
        ? Colors.white
        : const Color(0xFF6750A4);
    final progressColor = widget.isUser
        ? Colors.white
        : const Color(0xFF6750A4);
    final remainingColor = widget.isUser
        ? Colors.white70
        : Colors.grey[500];

    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: buttonBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: iconColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatDuration(remaining),
                    style: TextStyle(
                      fontSize: 10,
                      color: remainingColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds;
    if (totalSeconds <= 0) return '0s';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes}m${seconds}s';
  }
}

class _ToolStatusBubble extends StatelessWidget {
  final ChatMessage message;

  const _ToolStatusBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(width: 40),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _statusIcon,
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _backgroundColor {
    switch (message.toolStatus) {
      case 'completed':
        return const Color(0xFFE8F5E9);
      case 'failed':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  Widget get _statusIcon {
    switch (message.toolStatus) {
      case 'completed':
        return const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32));
      case 'failed':
        return const Icon(Icons.error, size: 14, color: Color(0xFFC62828));
      default:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
          ),
        );
    }
  }

  String get _label {
    final name = message.toolName ?? 'tool';
    switch (name) {
      case 'call_emergency_contact':
        return message.toolStatus == 'completed'
            ? (message.toolResult ?? '✅ Contact called')
            : message.toolStatus == 'failed'
            ? (message.toolResult ?? '❌ Call failed')
            : '📞 Calling emergency contact...';
      case 'get_current_location':
        return message.toolStatus == 'completed'
            ? (message.toolResult ?? '📍 Location obtained')
            : message.toolStatus == 'failed'
            ? (message.toolResult ?? '❌ Location failed')
            : '📍 Getting your location...';
      case 'list_emergency_contacts':
        return message.toolStatus == 'completed'
            ? (message.toolResult ?? '📋 Contacts loaded')
            : message.toolStatus == 'failed'
            ? (message.toolResult ?? '❌ Failed to load contacts')
            : '📋 Fetching contacts...';
      case 'send_emergency_alert':
        return message.toolStatus == 'completed'
            ? (message.toolResult ?? '🚨 Alert sent')
            : message.toolStatus == 'failed'
            ? (message.toolResult ?? '❌ Alert failed')
            : '🚨 Sending emergency alert...';
      default:
        return message.toolStatus == 'completed'
            ? '✅ $name completed'
            : message.toolStatus == 'failed'
            ? '❌ $name failed'
            : '⏳ Running $name...';
    }
  }
}
