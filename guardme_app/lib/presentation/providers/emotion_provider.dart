import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardme_app/core/constants.dart';
import 'package:guardme_app/presentation/providers/tool_service.dart';
import 'package:openai_dart/openai_dart.dart';

class EmotionState {
  final bool isLoading;
  final bool? isDistressed;
  final String? error;
  final String? calledContactName;

  const EmotionState({
    this.isLoading = false,
    this.isDistressed,
    this.error,
    this.calledContactName,
  });

  EmotionState copyWith({
    bool? isLoading,
    bool? isDistressed,
    String? error,
    String? calledContactName,
  }) {
    return EmotionState(
      isLoading: isLoading ?? this.isLoading,
      isDistressed: isDistressed ?? this.isDistressed,
      error: error,
      calledContactName: calledContactName ?? this.calledContactName,
    );
  }
}

class EmotionNotifier extends StateNotifier<EmotionState> {
  final Ref _ref;

  EmotionNotifier(this._ref) : super(const EmotionState());

  Future<void> analyzeImage(File imageFile) async {
    debugPrint('[Emotion] Starting analyzeImage...');
    state = state.copyWith(isLoading: true, error: null, isDistressed: null, calledContactName: null);

    try {
      debugPrint('[Emotion] Reading image file: ${imageFile.path}');
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      debugPrint('[Emotion] Image size: ${bytes.length} bytes');
      debugPrint('[Emotion] Base64 length: ${base64Image.length} chars');

      final apiKey = AppConstants.opencodeGoApiKey;
      final baseUrl = AppConstants.openaiBaseUrl;
      debugPrint('[Emotion] API Key length: ${apiKey.length}');
      debugPrint('[Emotion] Base URL: $baseUrl');
      debugPrint('[Emotion] Expected endpoint: $baseUrl/chat/completions');

      if (apiKey.isEmpty) {
        debugPrint('[Emotion] ERROR: API key is empty!');
        state = state.copyWith(
          isLoading: false,
          error: 'API key not configured. Check .env file.',
        );
        return;
      }

      debugPrint('[Emotion] Creating OpenAIClient...');
      final client = OpenAIClient(
        config: OpenAIConfig(
          authProvider: ApiKeyProvider(apiKey),
          baseUrl: baseUrl,
        ),
      );
      debugPrint('[Emotion] Client created successfully');

      final request = ChatCompletionCreateRequest(
          model: 'mimo-v2.5',
          maxTokens: 30000,
        messages: [
          ChatMessage.user([
            ContentPart.text("Analyze this person's facial expression for ANY signs of distress, fear, anxiety, discomfort, sadness, tension, worry, or being scared. Be highly sensitive — even subtle signs like furrowed brows, tight lips, wide eyes, tense jaw, forced smile, or any uneasy expression should count. If there is ANY doubt or even a slight indication of fear or distress, flag it as true. Only return false if the person is clearly calm, relaxed, and genuinely happy.\n\n"
                "You MUST respond with EXACTLY this JSON format, using these exact field names:\n"
                '{"distressed": true, "confidence": 0.95}\n\n'
                'The "distressed" field must be a boolean (true or false). The "confidence" field must be a number between 0 and 1.\n'
                "Do NOT use any other field names. Do NOT add any other fields. Do NOT wrap in markdown code blocks. Return ONLY the JSON object."),
            ContentPart.imageBase64(
              data: base64Image,
              mediaType: 'image/jpeg',
              detail: ImageDetail.high,
            ),
          ]),
        ],
      );
      debugPrint('[Emotion] Request built: model=${request.model}, maxTokens=${request.maxTokens}');

      debugPrint('[Emotion] Sending API request...');
      final response = await client.chat.completions.create(request);
      debugPrint('[Emotion] Response received!');
      debugPrint('[Emotion] Response model: ${response.model}');

      final tokens = response.usage;
      if (tokens != null) {
        debugPrint('[Emotion] Response usage: input=${tokens.promptTokens}, output=${tokens.completionTokens}');
      }

      final text = response.text;
      debugPrint('[Emotion] Response text: $text');

      if (text != null && text.isNotEmpty) {
        debugPrint('[Emotion] Parsing JSON...');

        String jsonText = text.trim();
        final codeBlockRegex = RegExp(r'```(?:json)?\s*(\{.*?\})\s*```', dotAll: true);
        final match = codeBlockRegex.firstMatch(jsonText);
        if (match != null) {
          jsonText = match.group(1)!.trim();
          debugPrint('[Emotion] Stripped code fences');
        } else {
          final firstBrace = jsonText.indexOf('{');
          final lastBrace = jsonText.lastIndexOf('}');
          if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
            jsonText = jsonText.substring(firstBrace, lastBrace + 1);
            debugPrint('[Emotion] Extracted JSON from text');
          }
        }

        debugPrint('[Emotion] JSON to parse: $jsonText');
        final json = jsonDecode(jsonText) as Map<String, dynamic>;
        debugPrint('[Emotion] Parsed JSON: $json');

        final distressed = (json['distressed'] as bool?) ??
            (json['distress_detected'] as bool?) ??
            (json['is_showing_distress'] as bool?) ??
            (json['is_distressed'] as bool?) ??
            (json['shows_distress_or_fear'] as bool?) ??
            (json['shows_distress'] as bool?) ??
            (json['distress'] as bool?) ??
            (json['fear'] as bool?) ??
            false;
        final confidence = json['confidence'] ?? json['confidence_score'];
        debugPrint('[Emotion] distressed=$distressed, confidence=$confidence');
        state = state.copyWith(
          isLoading: false,
          isDistressed: distressed,
        );

        if (distressed) {
          debugPrint('[Emotion] DISTRESS DETECTED! Auto-calling emergency contact...');
          await _callEmergencyContact();
        }
      } else {
        debugPrint('[Emotion] ERROR: Response text was empty');
        state = state.copyWith(
          isLoading: false,
          error: 'No response text from model',
        );
      }

      client.close();
      debugPrint('[Emotion] Client closed. Done.');
    } on ApiException catch (e) {
      debugPrint('[Emotion] ApiException: status=${e.statusCode}, message=${e.message}');
      debugPrint('[Emotion] ApiException details: ${e.body}');
      state = state.copyWith(
        isLoading: false,
        error: 'API Error ${e.statusCode}: ${e.message}',
      );
    } on OpenAIException catch (e) {
      debugPrint('[Emotion] OpenAIException: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: 'OpenAI SDK Error: ${e.toString()}',
      );
    } catch (e, stackTrace) {
      debugPrint('[Emotion] UNEXPECTED ERROR: ${e.toString()}');
      debugPrint('[Emotion] STACK TRACE:\n$stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  Future<void> _callEmergencyContact() async {
    try {
      debugPrint('[Emotion] Using ToolService to call emergency contact...');
      final toolService = _ref.read(toolServiceProvider);
      final result = await toolService.emergencyCall();
      final success = result['success'] == true;
      debugPrint('[Emotion] ToolService result: success=$success, data=$result');
      if (success) {
        state = state.copyWith(
          calledContactName: result['contactName'] as String?,
        );
      } else {
        state = state.copyWith(
          error: result['error'] as String? ?? 'Failed to call emergency contact',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[Emotion] ERROR calling emergency contact: $e');
      debugPrint('[Emotion] STACK TRACE:\n$stackTrace');
      state = state.copyWith(
        error: 'Error calling emergency contact: $e',
      );
    }
  }

  void reset() {
    debugPrint('[Emotion] Resetting state');
    state = const EmotionState();
  }
}

final emotionProvider =
    StateNotifierProvider<EmotionNotifier, EmotionState>((ref) {
  return EmotionNotifier(ref);
});
