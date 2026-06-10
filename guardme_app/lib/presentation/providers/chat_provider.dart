import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardme_app/core/constants.dart';
import 'package:guardme_app/domain/entities/chat_message.dart';
import 'package:guardme_app/presentation/providers/contact_provider.dart';
import 'package:openai_dart/openai_dart.dart' as openai;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isRecording;
  final Duration recordingDuration;
  final String? error;
  final bool? isDistressed;
  final String? calledContactName;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
    this.error,
    this.isDistressed,
    this.calledContactName,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isRecording,
    Duration? recordingDuration,
    String? error,
    bool? isDistressed,
    String? calledContactName,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      error: error,
      isDistressed: isDistressed ?? this.isDistressed,
      calledContactName: calledContactName ?? this.calledContactName,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _recordingTimer;
  String? _currentRecordingPath;
  bool _distressCallInitiated = false;

  // Temporary store for audio base64 data (not persisted — too large for SP)
  final Map<String, String> _pendingAudioData = {};

  static const _historyKey = 'guard_intelligence_history';
  static const _systemPrompt = '''
You are Guard Intelligence, an AI safety assistant embedded in the GuardMe personal safety app.
Your job is to help the user stay safe, analyze their surroundings from photos, and check in on their wellbeing.

You can hear voice messages directly AND see images directly.

DISTRESS DETECTION RULES — FOLLOW THESE EXACTLY:
1. When you hear voice messages, analyze the tone, pitch, crying, screaming, panic, and ANY emotional distress. If the user is crying, screaming, asking for help, or sounds panicked, you MUST append [DISTRESS:true].
2. When you see images, analyze the person's facial expression for ANY signs of distress, fear, anxiety, discomfort, sadness, tension, or being scared. Look for furrowed brows, tight lips, wide eyes, tense jaw, forced smiles, or uneasy expressions. If ANY of these are present, you MUST append [DISTRESS:true].
3. When reading text, if the user mentions being scared, in danger, hurt, or asks for help, you MUST append [DISTRESS:true].
4. Do NOT hesitate. If there is ANY indication of distress in text, voice, or image, append [DISTRESS:true].

Behavior:
- Be concise, supportive, and protective.
- If the user sends a photo, describe anything relevant to their safety.
- At the very end of your response, on its own line, append exactly this tag if you detected ANY distress:
[DISTRESS:true]

If no distress was detected, do NOT include the tag.
''';

  ChatNotifier(this._ref) : super(const ChatState()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historyKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        final messages = decoded
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(messages: messages);
      }
    } catch (e) {
      debugPrint('[Chat] Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          jsonEncode(state.messages.map((m) => m.toJson()).toList());
      await prefs.setString(_historyKey, encoded);
    } catch (e) {
      debugPrint('[Chat] Error saving history: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearChat() {
    state = state.copyWith(messages: []);
    _pendingAudioData.clear();
    _saveHistory();
  }

  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    final granted = await requestMicPermission();
    if (!granted) {
      state = state.copyWith(error: 'Microphone permission denied');
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/guard_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      _currentRecordingPath = path;

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: path,
      );

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        state = state.copyWith(
          recordingDuration: state.recordingDuration +
              const Duration(seconds: 1),
        );
      });

      state = state.copyWith(
        isRecording: true,
        recordingDuration: Duration.zero,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Could not start recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    _recordingTimer?.cancel();
    if (!state.isRecording) return null;

    try {
      final path = await _recorder.stop();
      state = state.copyWith(
        isRecording: false,
        recordingDuration: Duration.zero,
      );
      return path ?? _currentRecordingPath;
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        recordingDuration: Duration.zero,
        error: 'Recording failed',
      );
      return null;
    }
  }

  void cancelRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (_currentRecordingPath != null) {
      try {
        await File(_currentRecordingPath!).delete();
      } catch (_) {}
    }
    _currentRecordingPath = null;
    state = state.copyWith(
      isRecording: false,
      recordingDuration: Duration.zero,
    );
  }

  String _generateId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000}';
  }

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    await _addUserMessage(text: text.trim());
  }

  Future<void> sendImage(File imageFile, {String? textPrompt}) async {
    await _addUserMessage(
      text: textPrompt ?? '',
      imagePath: imageFile.path,
    );
  }

  Future<void> sendVoice(String audioPath, {String? transcription}) async {
    try {
      final bytes = await File(audioPath).readAsBytes();
      final base64Audio = base64Encode(bytes);
      final id = _generateId();
      _pendingAudioData[id] = base64Audio;

      await _addUserMessage(
        text: transcription ?? '[Voice message]',
        audioPath: audioPath,
        transcription: transcription,
        pendingAudioId: id,
      );
    } catch (e) {
      state = state.copyWith(error: 'Could not read audio file: $e');
    }
  }

  Future<void> _addUserMessage({
    required String text,
    String? imagePath,
    String? audioPath,
    String? transcription,
    String? pendingAudioId,
    bool triggerResponse = true,
  }) async {
    final userMessage = ChatMessage(
      id: pendingAudioId ?? _generateId(),
      role: 'user',
      text: text,
      imagePath: imagePath,
      audioPath: audioPath,
      transcription: transcription,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMessage];
    state = state.copyWith(
      messages: updatedMessages,
      isLoading: triggerResponse,
      error: null,
    );
    await _saveHistory();
    if (triggerResponse) {
      await _streamResponse(updatedMessages);
    }
  }

  Future<void> _streamResponse(List<ChatMessage> allMessages) async {
    try {
      final apiKey = AppConstants.opencodeGoApiKey;
      final baseUrl = AppConstants.openaiBaseUrl;
      if (apiKey.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'API key not configured');
        return;
      }

      final client = openai.OpenAIClient(
        config: openai.OpenAIConfig(
          authProvider: openai.ApiKeyProvider(apiKey),
          baseUrl: baseUrl,
        ),
      );

      final apiMessages = <openai.ChatMessage>[
        const openai.SystemMessage(content: _systemPrompt),
        ...allMessages
            .sublist(
              allMessages.length > 20 ? allMessages.length - 20 : 0,
            )
            .map((m) {
          if (m.role == 'user') {
            final parts = <openai.ContentPart>[];

            // Add text if present
            if (m.text != null && m.text!.isNotEmpty) {
              parts.add(openai.ContentPart.text(m.text!));
            }

            // Add image if present
            if (m.imagePath != null) {
              final imgBytes = File(m.imagePath!).readAsBytesSync();
              parts.add(openai.ContentPart.imageBase64(
                data: base64Encode(imgBytes),
                mediaType: 'image/jpeg',
                detail: openai.ImageDetail.high,
              ));
            }

            // Add audio directly if pending
            if (m.audioPath != null && _pendingAudioData.containsKey(m.id)) {
              parts.add(openai.ContentPart.inputAudio(
                data: _pendingAudioData.remove(m.id)!,
                format: openai.AudioFormat.wav,
              ));
            }

            if (parts.length == 1 && parts.first is openai.TextContentPart) {
              return openai.UserMessage(
                content: openai.UserMessageContent.text(m.text ?? ''),
              );
            }
            return openai.UserMessage(
              content: openai.UserMessageContent.parts(parts),
            );
          }
          return openai.AssistantMessage(content: m.text);
        }),
      ];

      final aiMessageId = _generateId();
      final initialAiMessage = ChatMessage(
        id: aiMessageId,
        role: 'assistant',
        text: '',
        timestamp: DateTime.now(),
        isLoading: true,
      );

      state = state.copyWith(messages: [...state.messages, initialAiMessage]);

      final request = openai.ChatCompletionCreateRequest(
        model: 'mimo-v2.5',
        maxTokens: 100000,
        messages: apiMessages,
      );

      _distressCallInitiated = false;
      final stream = client.chat.completions.createStream(request);
      final buffer = StringBuffer();

      await for (final event in stream) {
        final delta = event.textDelta;
        if (delta != null) {
          buffer.write(delta);
          final updatedList = state.messages.map((m) {
            if (m.id == aiMessageId) {
              return m.copyWith(
                text: buffer.toString(),
                isLoading: false,
              );
            }
            return m;
          }).toList();
          state = state.copyWith(messages: updatedList);

          // Check for distress tag as soon as it appears in the stream
          if (!_distressCallInitiated &&
              buffer.toString().toLowerCase().contains('[distress:true]')) {
            _distressCallInitiated = true;
            state = state.copyWith(isDistressed: true);
            _callEmergencyContact();
          }
        }
      }

      client.close();

      final fullResponse = buffer.toString();
      final distressDetected = fullResponse.toLowerCase().contains('[distress:true]');
      final cleanResponse = fullResponse.replaceAllMapped(
        RegExp(r'\[DISTRESS:\s*TRUE\]', caseSensitive: false),
        (_) => '',
      ).trim();

      final finalList = state.messages.map((m) {
        if (m.id == aiMessageId) {
          return m.copyWith(
            text: cleanResponse.isEmpty ? '(No response)' : cleanResponse,
            isLoading: false,
          );
        }
        return m;
      }).toList();

      state = state.copyWith(messages: finalList, isLoading: false);
      await _saveHistory();

      if (distressDetected && !_distressCallInitiated) {
        _distressCallInitiated = true;
        state = state.copyWith(isDistressed: true);
        await _callEmergencyContact();
        state = state.copyWith(isDistressed: false);
      }
      if (_distressCallInitiated) {
        state = state.copyWith(isDistressed: false);
      }
    } on openai.ApiException catch (e) {
      _removeLoadingMessage();
      state = state.copyWith(
        isLoading: false,
        error: 'API Error ${e.statusCode}: ${e.message}',
      );
    } on openai.OpenAIException catch (e) {
      _removeLoadingMessage();
      state = state.copyWith(isLoading: false, error: 'OpenAI Error: $e');
    } catch (e, st) {
      debugPrint('[Chat] Error: $e\n$st');
      _removeLoadingMessage();
      state = state.copyWith(isLoading: false, error: 'Unexpected error: $e');
    }
  }

  void _removeLoadingMessage() {
    final filtered = state.messages.where((m) => !m.isLoading).toList();
    state = state.copyWith(messages: filtered);
  }

  Future<void> _callEmergencyContact() async {
    try {
      final contactState = _ref.read(contactProvider);
      var contacts = contactState.contacts;

      if (contacts.isEmpty) {
        await _ref.read(contactProvider.notifier).loadContacts();
        contacts = _ref.read(contactProvider).contacts;
      }

      if (contacts.isEmpty) {
        state = state.copyWith(
          error: 'Distress detected but no emergency contacts available!',
        );
        return;
      }

      final contact = contacts.first;
      state = state.copyWith(calledContactName: contact.name);
      final uri = Uri(scheme: 'tel', path: contact.phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        state = state.copyWith(
          error: 'Cannot initiate call to ${contact.name}',
        );
      }
    } catch (e) {
      debugPrint('[Chat] Error calling emergency: $e');
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
