import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardme_app/core/constants.dart';
import 'package:guardme_app/domain/entities/chat_message.dart';
import 'package:guardme_app/presentation/providers/tool_service.dart';
import 'package:openai_dart/openai_dart.dart' as openai;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final List<openai.ChatMessage> _pendingToolMessages = [];

  // Temporary store for audio base64 data (not persisted — too large for SP)
  final Map<String, String> _pendingAudioData = {};

  static const _historyKey = 'guard_intelligence_history';
  static const _systemPrompt = '''
You are Guard Intelligence, an AI safety assistant embedded in the GuardMe personal safety app.
Your job is to help the user stay safe, analyze their surroundings from photos, and check in on their wellbeing.

You can hear voice messages directly AND see images directly.

You have access to tools that you can use to help the user:

1. call_emergency_contact — Call an emergency contact immediately. Use this when the user is in distress, danger, scared, hurt, or asks for emergency help. Specify contact_name to call a specific person.
2. get_current_location — Get the user's current GPS location coordinates. Use this to help with navigation, share location in emergencies, or provide location-aware assistance.
3. list_emergency_contacts — List all the user's saved emergency contacts with names and phone numbers.
4. send_emergency_alert — Send an emergency alert with current location to all emergency contacts.

CRITICAL DISTRESS DETECTION:
- When you hear voice messages, analyze tone, pitch, crying, screaming, panic, and ANY emotional distress.
- When you see images, analyze facial expressions for ANY signs of distress, fear, anxiety, discomfort, sadness, tension, worry, or being scared.
- When reading text, if the user mentions being scared, in danger, hurt, or asks for help.
- If ANY distress is detected, use the call_emergency_contact tool immediately.
- Do NOT hesitate. If there is ANY indication of distress, call an emergency contact.

Behavior:
- Be concise, supportive, and protective.
- If the user sends a photo, describe anything relevant to their safety.
- When you use a tool, briefly explain what you are doing.
- If a tool fails, let the user know and suggest alternatives.
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
    _pendingToolMessages.clear();
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
      _pendingToolMessages.clear();
      await _streamResponse(updatedMessages);
    }
  }

  Future<void> _streamResponse(List<ChatMessage> allMessages, {int toolDepth = 0}) async {
    if (toolDepth > 5) {
      state = state.copyWith(error: 'Maximum tool call depth reached');
      return;
    }

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

      // Build API messages: system prompt + displayed messages (filter out tool status) + pending tool round messages
      final apiMessages = <openai.ChatMessage>[
        const openai.SystemMessage(content: _systemPrompt),
        ...allMessages
            .where((m) => !m.isToolStatus)
            .toList()
            .sublist(
              allMessages.length > 20 ? allMessages.length - 20 : 0,
            )
            .map(_toApiMessage),
        ..._pendingToolMessages,
      ];

      final request = openai.ChatCompletionCreateRequest(
        model: 'mimo-v2.5',
        maxTokens: 100000,
        messages: apiMessages,
        tools: ToolService.toolDefinitions,
      );

      final stream = client.chat.completions.createStream(request);
      final allEvents = <openai.ChatStreamEvent>[];
      String? aiMessageId;
      final buffer = StringBuffer();

      await for (final event in stream) {
        allEvents.add(event);
        final delta = event.textDelta;
        if (delta != null) {
          // Lazily create the assistant bubble on first text token
          if (aiMessageId == null) {
            aiMessageId = _generateId();
            state = state.copyWith(messages: [
              ...state.messages,
              ChatMessage(
                id: aiMessageId,
                role: 'assistant',
                text: '',
                timestamp: DateTime.now(),
                isLoading: true,
              ),
            ]);
          }
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
        }
      }

      // Check for tool calls by building accumulator from all events
      final acc = openai.ChatStreamAccumulator();
      for (final event in allEvents) {
        acc.add(event);
      }

      if (acc.hasToolCalls) {
        client.close();

        // No loading message to remove since we never created one for tool calls

        // Echo assistant's tool calls into pending messages
        _pendingToolMessages.add(
          openai.AssistantMessage(content: null, toolCalls: acc.toolCalls),
        );

        // Execute each tool
        final toolService = _ref.read(toolServiceProvider);
        for (final tc in acc.toolCalls) {
          _addToolStatusMessage(tc.function.name, 'running', tc);

          final result = await toolService.executeTool(tc);

          final success = result['success'] == true ||
              (result['error'] == null &&
                  result.containsKey('latitude'));
          _updateToolStatus(
            tc.function.name,
            success ? 'completed' : 'failed',
            result,
          );

          _pendingToolMessages.add(
            openai.ToolMessage(
              toolCallId: tc.id,
              content: jsonEncode(result),
            ),
          );
        }

        // Recurse to get the model's text response after tool execution
        await _streamResponse(allMessages, toolDepth: toolDepth + 1);
        return;
      }

      client.close();

      // No tool calls — handle the text response
      final fullResponse = buffer.toString();
      if (aiMessageId != null) {
        final finalList = state.messages.map((m) {
          if (m.id == aiMessageId) {
            return m.copyWith(
              text: fullResponse.isEmpty ? '(No response)' : fullResponse,
              isLoading: false,
            );
          }
          return m;
        }).toList();
        state = state.copyWith(messages: finalList, isLoading: false);
        await _saveHistory();
      } else {
        state = state.copyWith(isLoading: false);
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

  openai.ChatMessage _toApiMessage(ChatMessage m) {
    if (m.role == 'user') {
      final parts = <openai.ContentPart>[];
      if (m.text != null && m.text!.isNotEmpty) {
        parts.add(openai.ContentPart.text(m.text!));
      }
      if (m.imagePath != null) {
        final imgBytes = File(m.imagePath!).readAsBytesSync();
        parts.add(openai.ContentPart.imageBase64(
          data: base64Encode(imgBytes),
          mediaType: 'image/jpeg',
          detail: openai.ImageDetail.high,
        ));
      }
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
  }

  void _addToolStatusMessage(String toolName, String status, openai.ToolCall tc) {
    final statusMsg = ChatMessage(
      id: _generateId(),
      role: 'assistant',
      toolName: toolName,
      toolStatus: status,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, statusMsg]);
  }

  void _updateToolStatus(String toolName, String status, Map<String, dynamic> result) {
    final updatedList = state.messages.map((m) {
      if (m.isToolStatus && m.toolName == toolName && m.toolStatus == 'running') {
        return m.copyWith(
          toolStatus: status,
          toolResult: status == 'completed'
              ? _describeToolResult(toolName, result)
              : 'Failed: ${result['error'] ?? 'Unknown error'}',
        );
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updatedList);
  }

  String _describeToolResult(String toolName, Map<String, dynamic> result) {
    switch (toolName) {
      case 'call_emergency_contact':
        return 'Called ${result['contactName'] ?? 'emergency contact'}';
      case 'get_current_location':
        return 'Location: ${result['latitude']?.toStringAsFixed(4)}, ${result['longitude']?.toStringAsFixed(4)}';
      case 'list_emergency_contacts':
        final contacts = result['contacts'] as List?;
        if (contacts == null || contacts.isEmpty) return 'No contacts found';
        return '${contacts.length} contact(s) found';
      case 'send_emergency_alert':
        return result['success'] == true ? 'Alert sent' : 'Failed to send alert';
      default:
        return 'Completed';
    }
  }

  void _removeLoadingMessage() {
    final filtered = state.messages.where((m) => !m.isLoading).toList();
    state = state.copyWith(messages: filtered);
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
