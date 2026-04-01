import 'dart:convert';
import 'dart:io';

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'vision_identification_service.dart';

class ClaudeVisionService implements VisionIdentificationService {
  AnthropicClient? _client;

  static const _model = 'claude-sonnet-4-20250514';
  static const _maxTokens = 256;
  static const _timeout = Duration(seconds: 30);

  static const _systemPrompt =
      'You are a toy identification expert. Identify the toy in the image. '
      'Return JSON only, no other text. '
      'Format: {"name": "specific product name", '
      '"category": "one of: Action Figures, Dolls, Building Blocks, Vehicles, '
      'Puzzles, Board Games, Stuffed Animals, Educational, Outdoor, Other", '
      '"description": "1-2 sentence description"}';

  bool get isConfigured {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
    return apiKey != null && apiKey.isNotEmpty;
  }

  AnthropicClient _getClient() {
    if (_client != null) return _client!;
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
    _client = AnthropicClient.withApiKey(apiKey);
    return _client!;
  }

  @override
  Future<ToyIdentification> identifyToy(File imageFile) async {
    if (!isConfigured) {
      throw Exception('Anthropic API key not configured');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final extension = imageFile.path.toLowerCase();
    final mediaType = extension.endsWith('.png')
        ? ImageMediaType.png
        : ImageMediaType.jpeg;

    final client = _getClient();

    final response = await client.messages
        .create(
          MessageCreateRequest(
            model: _model,
            maxTokens: _maxTokens,
            system: SystemPrompt.text(_systemPrompt),
            messages: [
              InputMessage(
                role: MessageRole.user,
                content: MessageContent.blocks([
                  InputContentBlock.image(
                    ImageSource.base64(
                      data: base64Image,
                      mediaType: mediaType,
                    ),
                  ),
                  InputContentBlock.text('What toy is this?'),
                ]),
              ),
            ],
          ),
        )
        .timeout(_timeout);

    final textBlock = response.content.whereType<TextBlock>().firstOrNull;
    final text = textBlock?.text ?? '{}';

    return ToyIdentification.tryParseResponse(text);
  }
}
