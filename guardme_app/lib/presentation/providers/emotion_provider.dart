import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardme_app/core/constants.dart';
import 'package:guardme_app/presentation/providers/contact_provider.dart';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

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

    final loggingSubscription = Logger.root.onRecord.listen((record) {
      debugPrint(
        '[AnthropicSDK] ${record.level.name}: ${record.message}',
      );
      if (record.error != null) {
        debugPrint('[AnthropicSDK] ERROR: ${record.error}');
      }
      if (record.stackTrace != null) {
        debugPrint('[AnthropicSDK] STACK: ${record.stackTrace}');
      }
    });

    try {
      debugPrint('[Emotion] Reading image file: ${imageFile.path}');
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      debugPrint('[Emotion] Image size: ${bytes.length} bytes');
      debugPrint('[Emotion] Base64 length: ${base64Image.length} chars');

      final apiKey = AppConstants.opencodeGoApiKey;
      final baseUrl = AppConstants.anthropicBaseUrl;
      debugPrint('[Emotion] API Key length: ${apiKey.length}');
      debugPrint('[Emotion] Base URL: $baseUrl');
      debugPrint('[Emotion] Expected endpoint: $baseUrl/v1/messages');

      if (apiKey.isEmpty) {
        debugPrint('[Emotion] ERROR: API key is empty!');
        state = state.copyWith(
          isLoading: false,
          error: 'API key not configured. Check .env file.',
        );
        return;
      }

      debugPrint('[Emotion] Creating AnthropicClient with logLevel=ALL...');
      final client = AnthropicClient(
        config: AnthropicConfig(
          authProvider: ApiKeyProvider(apiKey),
          baseUrl: baseUrl,
          logLevel: Level.ALL,
        ),
      );
      debugPrint('[Emotion] Client created successfully');

      final request = MessageCreateRequest(
          model: 'qwen3.7-plus',
          maxTokens: 30000,
          thinking: const ThinkingDisabled(),
        messages: [
          InputMessage.userBlocks([
            InputContentBlock.text(
              "Analyze this person's facial expression for ANY signs of distress, fear, anxiety, discomfort, sadness, tension, worry, or being scared. Be highly sensitive — even subtle signs like furrowed brows, tight lips, wide eyes, tense jaw, forced smile, or any uneasy expression should count. If there is ANY doubt or even a slight indication of fear or distress, flag it as true. Only return false if the person is clearly calm, relaxed, and genuinely happy.\n\n"
              "You MUST respond with EXACTLY this JSON format, using these exact field names:\n"
              '{"distressed": true, "confidence": 0.95}\n\n'
              'The "distressed" field must be a boolean (true or false). The "confidence" field must be a number between 0 and 1.\n'
              "Do NOT use any other field names. Do NOT add any other fields. Do NOT wrap in markdown code blocks. Return ONLY the JSON object.",
            ),
            InputContentBlock.image(
              ImageSource.base64(
                data: base64Image,
                mediaType: ImageMediaType.jpeg,
              ),
            ),
          ]),
        ],
        outputConfig: const OutputConfig(
          format: JsonOutputFormat(
            schema: {
              'type': 'object',
              'properties': {
                'distressed': {'type': 'boolean'},
                'confidence': {'type': 'number'},
              },
              'required': ['distressed', 'confidence'],
            },
          ),
        ),
      );
      debugPrint('[Emotion] Request built: model=${request.model}, maxTokens=${request.maxTokens}');

      debugPrint('[Emotion] Sending API request...');
      final response = await client.messages.create(request);
      debugPrint('[Emotion] Response received!');
      debugPrint('[Emotion] Response ID: ${response.id}');
      debugPrint('[Emotion] Response model: ${response.model}');
      debugPrint('[Emotion] Response stopReason: ${response.stopReason}');
      debugPrint('[Emotion] Response usage: input=${response.usage.inputTokens}, output=${response.usage.outputTokens}');

      final text = response.text;
      debugPrint('[Emotion] Response text: $text');

      if (text.isNotEmpty) {
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
      debugPrint('[Emotion] ApiException details: ${e.details}');
      state = state.copyWith(
        isLoading: false,
        error: 'API Error ${e.statusCode}: ${e.message}',
      );
    } on AnthropicException catch (e) {
      debugPrint('[Emotion] AnthropicException: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: 'Anthropic SDK Error: ${e.toString()}',
      );
    } catch (e, stackTrace) {
      debugPrint('[Emotion] UNEXPECTED ERROR: ${e.toString()}');
      debugPrint('[Emotion] STACK TRACE:\n$stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected error: ${e.toString()}',
      );
    } finally {
      await loggingSubscription.cancel();
    }
  }

  Future<void> _callEmergencyContact() async {
    try {
      debugPrint('[Emotion] Fetching emergency contacts...');
      final contactState = _ref.read(contactProvider);
      var contacts = contactState.contacts;

      if (contacts.isEmpty) {
        debugPrint('[Emotion] No contacts cached, loading from server...');
        await _ref.read(contactProvider.notifier).loadContacts();
        contacts = _ref.read(contactProvider).contacts;
      }

      if (contacts.isEmpty) {
        debugPrint('[Emotion] ERROR: No emergency contacts found!');
        state = state.copyWith(
          error: 'Distress detected but no emergency contacts available to call!',
        );
        return;
      }

      final contact = contacts.first;
      debugPrint('[Emotion] Calling contact: ${contact.name} (${contact.phone})');
      state = state.copyWith(calledContactName: contact.name);

      final uri = Uri(scheme: 'tel', path: contact.phone);
      if (await canLaunchUrl(uri)) {
        debugPrint('[Emotion] Launching phone dialer: $uri');
        await launchUrl(uri);
        debugPrint('[Emotion] Phone dialer launched successfully');
      } else {
        debugPrint('[Emotion] ERROR: Cannot launch phone dialer for $uri');
        state = state.copyWith(
          error: 'Cannot initiate call to ${contact.name}. Phone dialer not available.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[Emotion] ERROR calling emergency contact: $e');
      debugPrint('[Emotion] STACK TRACE:\n$stackTrace');
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
