import 'package:intl/intl.dart';

class ChatMessage {
  final String id;
  final String role; // 'user', 'assistant', or 'tool'
  final String? text;
  final String? imagePath;
  final String? audioPath;
  final String? transcription;
  final String? toolName;
  final String? toolStatus; // 'running', 'completed', 'failed'
  final String? toolResult;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.role,
    this.text,
    this.imagePath,
    this.audioPath,
    this.transcription,
    this.toolName,
    this.toolStatus,
    this.toolResult,
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
    String? toolName,
    String? toolStatus,
    String? toolResult,
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
      toolName: toolName ?? this.toolName,
      toolStatus: toolStatus ?? this.toolStatus,
      toolResult: toolResult ?? this.toolResult,
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
      if (toolName != null) 'toolName': toolName,
      if (toolStatus != null) 'toolStatus': toolStatus,
      if (toolResult != null) 'toolResult': toolResult,
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
      toolName: json['toolName'] as String?,
      toolStatus: json['toolStatus'] as String?,
      toolResult: json['toolResult'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isLoading: json['isLoading'] as bool? ?? false,
    );
  }

  String get formattedTime => DateFormat('HH:mm').format(timestamp);

  bool get hasMedia => imagePath != null || audioPath != null;

  bool get isToolStatus => toolName != null;
}
