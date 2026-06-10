import 'package:intl/intl.dart';

class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String? text;
  final String? imagePath;
  final String? audioPath;
  final String? transcription;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.role,
    this.text,
    this.imagePath,
    this.audioPath,
    this.transcription,
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? id,
    String? role,
    String? text,
    String? imagePath,
    String? audioPath,
    String? transcription,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      audioPath: audioPath ?? this.audioPath,
      transcription: transcription ?? this.transcription,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'imagePath': imagePath,
      'audioPath': audioPath,
      'transcription': transcription,
      'timestamp': timestamp.toIso8601String(),
      'isLoading': isLoading,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      text: json['text'] as String?,
      imagePath: json['imagePath'] as String?,
      audioPath: json['audioPath'] as String?,
      transcription: json['transcription'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isLoading: json['isLoading'] as bool? ?? false,
    );
  }

  String get formattedTime => DateFormat('HH:mm').format(timestamp);

  bool get hasMedia => imagePath != null || audioPath != null;
}
