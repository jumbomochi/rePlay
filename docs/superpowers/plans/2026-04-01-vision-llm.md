# Vision LLM Toy Identification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an "Identify with AI" button on the capture screen that sends a toy photo to Claude's vision API and auto-fills name, category, and description.

**Architecture:** A provider-agnostic `VisionIdentificationService` interface with a `ClaudeVisionService` implementation using `anthropic_sdk_dart`. API key loaded from `.env` via `flutter_dotenv`. The button is on-demand — ML Kit remains the free default.

**Tech Stack:** Flutter, Riverpod, anthropic_sdk_dart, flutter_dotenv

---

## File Map

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `anthropic_sdk_dart`, `flutter_dotenv` |
| `.env.example` | New: API key template |
| `lib/main.dart` | Load dotenv at startup |
| `lib/core/services/vision_identification_service.dart` | New: interface + ToyIdentification model |
| `lib/core/services/claude_vision_service.dart` | New: Claude API implementation |
| `lib/core/services/services_provider.dart` | Add `visionIdentificationServiceProvider` |
| `lib/features/capture/screens/capture_screen.dart` | Add "Identify with AI" button |
| `test/vision_identification_test.dart` | New: unit tests for response parsing |

---

### Task 1: Dependencies and Environment Setup

**Files:**
- Modify: `pubspec.yaml`
- Create: `.env.example`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add dependencies to pubspec.yaml**

In `pubspec.yaml`, add under the `# Sharing` section (before `# Utilities`):

```yaml
  # AI Vision
  anthropic_sdk_dart: ^1.4.1
  flutter_dotenv: ^5.2.1
```

Also add the `.env` asset. Under the `flutter:` section, after `uses-material-design: true`, add:

```yaml
  assets:
    - .env
```

- [ ] **Step 2: Create .env.example**

Create `.env.example` at project root:

```
ANTHROPIC_API_KEY=your_api_key_here
```

- [ ] **Step 3: Create .env file**

Create `.env` at project root (this file is already in `.gitignore`):

```
ANTHROPIC_API_KEY=
```

- [ ] **Step 4: Update main.dart to load dotenv**

Replace `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env').catchError((_) {});
  runApp(
    const ProviderScope(
      child: RePlayApp(),
    ),
  );
}
```

Note: `.catchError((_) {})` ensures the app doesn't crash if `.env` doesn't exist. The API key will just be null/empty and the "Identify with AI" button will be hidden.

- [ ] **Step 5: Install dependencies**

Run: `flutter pub get`
Expected: Dependencies resolved successfully.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock .env.example lib/main.dart
git commit -m "chore: add anthropic_sdk_dart and flutter_dotenv dependencies"
```

---

### Task 2: VisionIdentificationService Interface and ToyIdentification Model

**Files:**
- Create: `lib/core/services/vision_identification_service.dart`
- Create: `test/vision_identification_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/vision_identification_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:replay/core/services/vision_identification_service.dart';

void main() {
  group('ToyIdentification.fromJson', () {
    test('parses valid JSON correctly', () {
      final json = {
        'name': 'Buzz Lightyear',
        'category': 'Action Figures',
        'description': 'Space ranger action figure from Toy Story',
      };

      final result = ToyIdentification.fromJson(json);

      expect(result.name, 'Buzz Lightyear');
      expect(result.category, 'Action Figures');
      expect(result.description, 'Space ranger action figure from Toy Story');
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{
        'name': 'Some Toy',
      };

      final result = ToyIdentification.fromJson(json);

      expect(result.name, 'Some Toy');
      expect(result.category, 'Other');
      expect(result.description, '');
    });

    test('unrecognized category defaults to Other', () {
      final json = {
        'name': 'Fidget Spinner',
        'category': 'Gadgets',
        'description': 'A spinning toy',
      };

      final result = ToyIdentification.fromJson(json);

      expect(result.category, 'Other');
    });

    test('tryParseResponse handles valid JSON string', () {
      const response = '{"name": "LEGO Set", "category": "Building Blocks", "description": "A building set"}';

      final result = ToyIdentification.tryParseResponse(response);

      expect(result.name, 'LEGO Set');
      expect(result.category, 'Building Blocks');
    });

    test('tryParseResponse handles JSON with markdown code block', () {
      const response = '```json\n{"name": "LEGO Set", "category": "Building Blocks", "description": "A building set"}\n```';

      final result = ToyIdentification.tryParseResponse(response);

      expect(result.name, 'LEGO Set');
      expect(result.category, 'Building Blocks');
    });

    test('tryParseResponse falls back to raw text on invalid JSON', () {
      const response = 'This is a Buzz Lightyear action figure';

      final result = ToyIdentification.tryParseResponse(response);

      expect(result.name, 'This is a Buzz Lightyear action figure');
      expect(result.category, 'Other');
      expect(result.description, '');
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/vision_identification_test.dart`
Expected: FAIL — `ToyIdentification` doesn't exist.

- [ ] **Step 3: Implement the interface and model**

Create `lib/core/services/vision_identification_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import '../constants/app_constants.dart';

class ToyIdentification {
  final String name;
  final String category;
  final String description;

  const ToyIdentification({
    required this.name,
    required this.category,
    required this.description,
  });

  factory ToyIdentification.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Unknown Toy';
    final rawCategory = json['category'] as String? ?? 'Other';
    final description = json['description'] as String? ?? '';

    // Validate category against known categories
    final validCategories = AppConstants.categoryIcons.keys.toSet();
    final category = validCategories.contains(rawCategory) ? rawCategory : 'Other';

    return ToyIdentification(
      name: name,
      category: category,
      description: description,
    );
  }

  static ToyIdentification tryParseResponse(String response) {
    // Try to extract JSON from the response
    var jsonStr = response.trim();

    // Strip markdown code block if present
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr
          .replaceFirst(RegExp(r'^```json?\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '');
    }

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ToyIdentification.fromJson(json);
    } catch (_) {
      // If JSON parsing fails, use raw text as name
      return ToyIdentification(
        name: response.trim(),
        category: 'Other',
        description: '',
      );
    }
  }
}

abstract class VisionIdentificationService {
  Future<ToyIdentification> identifyToy(File imageFile);
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/vision_identification_test.dart`
Expected: All 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/vision_identification_service.dart test/vision_identification_test.dart
git commit -m "feat: add VisionIdentificationService interface and ToyIdentification model"
```

---

### Task 3: ClaudeVisionService Implementation

**Files:**
- Create: `lib/core/services/claude_vision_service.dart`

- [ ] **Step 1: Implement ClaudeVisionService**

Create `lib/core/services/claude_vision_service.dart`:

```dart
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
    _client = AnthropicClient(apiKey: apiKey);
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
        ? ImageMediaType.imagePng
        : ImageMediaType.imageJpeg;

    final client = _getClient();

    final response = await client
        .createMessage(
          request: CreateMessageRequest(
            model: Model.modelId(_model),
            maxTokens: _maxTokens,
            system: CreateMessageRequestSystem.text(_systemPrompt),
            messages: [
              Message(
                role: MessageRole.user,
                content: MessageContent.blocks([
                  Block.image(
                    source: ImageBlockSource(
                      type: ImageBlockSourceType.base64,
                      mediaType: mediaType,
                      data: base64Image,
                    ),
                  ),
                  const Block.text(text: 'What toy is this?'),
                ]),
              ),
            ],
          ),
        )
        .timeout(_timeout);

    final textBlock = response.content.firstWhere(
      (block) => block is TextBlock,
      orElse: () => const TextBlock(text: '{}'),
    ) as TextBlock;

    return ToyIdentification.tryParseResponse(textBlock.text);
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze lib/core/services/claude_vision_service.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/claude_vision_service.dart
git commit -m "feat: add ClaudeVisionService implementation"
```

---

### Task 4: Vision Service Provider

**Files:**
- Modify: `lib/core/services/services_provider.dart`

- [ ] **Step 1: Add provider**

In `lib/core/services/services_provider.dart`, add imports:

```dart
import 'claude_vision_service.dart';
import 'vision_identification_service.dart';
```

Add provider:

```dart
final visionIdentificationServiceProvider = Provider<ClaudeVisionService>((ref) {
  return ClaudeVisionService();
});
```

Note: Uses `ClaudeVisionService` as the concrete type (not the interface) so callers can access `isConfigured`.

- [ ] **Step 2: Run tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/services_provider.dart
git commit -m "feat: add visionIdentificationServiceProvider"
```

---

### Task 5: "Identify with AI" Button on Capture Screen

**Files:**
- Modify: `lib/features/capture/screens/capture_screen.dart`

- [ ] **Step 1: Add state field**

In `_CaptureScreenState`, add:

```dart
  bool _isIdentifying = false;
```

- [ ] **Step 2: Add the "Identify with AI" button**

In the `build` method, find the section after the AI labels:

```dart
                      if (_aiLabels.isNotEmpty) _buildAILabelsSection(),
                      const SizedBox(height: 16),
```

Replace with:

```dart
                      if (_aiLabels.isNotEmpty) _buildAILabelsSection(),
                      if (_imagePath != null) _buildIdentifyButton(),
                      const SizedBox(height: 16),
```

- [ ] **Step 3: Add _buildIdentifyButton method**

Add this method to `_CaptureScreenState`:

```dart
  Widget _buildIdentifyButton() {
    final visionService = ref.read(visionIdentificationServiceProvider);
    if (!visionService.isConfigured) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        onPressed: _isIdentifying ? null : _identifyWithAI,
        icon: _isIdentifying
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(_isIdentifying ? 'Identifying...' : 'Identify with AI'),
      ),
    );
  }
```

- [ ] **Step 4: Add _identifyWithAI method**

Add this method to `_CaptureScreenState`:

```dart
  Future<void> _identifyWithAI() async {
    if (_imagePath == null) return;

    setState(() {
      _isIdentifying = true;
    });

    try {
      final visionService = ref.read(visionIdentificationServiceProvider);
      final result = await visionService.identifyToy(File(_imagePath!));

      setState(() {
        _nameController.text = result.name;
        _descriptionController.text = result.description;
        _selectedCategory = result.category;
        _isIdentifying = false;
      });
    } catch (e) {
      setState(() {
        _isIdentifying = false;
      });

      if (mounted) {
        String message = 'Could not identify toy. Try again.';
        if (e.toString().contains('API key')) {
          message = 'Could not identify toy. Check your API key.';
        } else if (e.toString().contains('TimeoutException')) {
          message = 'Request timed out. Try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }
```

- [ ] **Step 5: Add import for services_provider if not already present**

The file already imports `services_provider.dart` — verify `visionIdentificationServiceProvider` is accessible. If not, add:

```dart
import 'dart:io';
```

(`dart:io` is already imported, and `services_provider.dart` is already imported.)

- [ ] **Step 6: Run all tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 7: Run flutter analyze**

Run: `flutter analyze`
Expected: No new issues.

- [ ] **Step 8: Commit**

```bash
git add lib/features/capture/screens/capture_screen.dart
git commit -m "feat: add Identify with AI button to capture screen"
```

---

### Task 6: Final Verification

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No new analysis issues.

- [ ] **Step 3: Fix any issues found**

If there are issues, fix and commit.
