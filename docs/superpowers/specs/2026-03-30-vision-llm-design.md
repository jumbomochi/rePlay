# Better Toy Identification with Vision LLM Design

## Overview

Add an "Identify with AI" button on the capture screen that sends the toy photo to Claude's vision API for specific toy identification. Returns name, category, and description to auto-fill the form. ML Kit remains the free/fast default; the LLM is on-demand.

## Architecture

A provider-agnostic `VisionIdentificationService` interface with a `ClaudeVisionService` implementation. This allows swapping to Gemini or GPT-4o in the future without changing the capture screen.

### Interface

```dart
abstract class VisionIdentificationService {
  Future<ToyIdentification> identifyToy(File imageFile);
}

class ToyIdentification {
  final String name;
  final String category;
  final String description;
}
```

### Claude Implementation

Uses the `anthropic_sdk_dart` package to call Claude's Messages API with a base64-encoded image. The system prompt constrains output to JSON matching the app's category set.

**Prompt:** "Identify this toy. Return JSON only, no other text. Format: {\"name\": \"specific product name\", \"category\": \"one of: Action Figures, Dolls, Building Blocks, Vehicles, Puzzles, Board Games, Stuffed Animals, Educational, Outdoor, Other\", \"description\": \"1-2 sentence description\"}"

**Model:** `claude-sonnet-4-20250514` (fast, cheap, good vision).

**Timeout:** 30 seconds.

## API Key Management

- API key stored in `.env` file at project root
- `.env` added to `.gitignore`
- `.env.example` committed as a template showing `ANTHROPIC_API_KEY=your_key_here`
- Loaded via `flutter_dotenv` package at app startup
- If no API key configured, the "Identify with AI" button is hidden

## Capture Screen Changes

After a photo is taken and ML Kit labels are displayed, show an "Identify with AI" button:

- Only visible when a photo has been taken and an API key is configured
- Button text: "Identify with AI" with a sparkle/auto_awesome icon
- Tapping shows a loading indicator on the button
- On success: auto-fills name, category dropdown, and description fields
- On error: shows a snackbar with "Could not identify toy. Try again." message
- User can still edit all auto-filled fields manually

## Error Handling

- **Network error:** Snackbar "No internet connection"
- **API error (rate limit, auth):** Snackbar "Could not identify toy. Check your API key."
- **Invalid JSON response:** Use raw text as name, default category to "Other", empty description
- **Unrecognized category:** Default to "Other"
- **Timeout (30s):** Snackbar "Request timed out. Try again."

## New Dependencies

- `anthropic_sdk_dart` — Dart client for the Anthropic API
- `flutter_dotenv` — load environment variables from `.env` file

## File Map

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `anthropic_sdk_dart` and `flutter_dotenv` |
| `.env.example` | New: template with `ANTHROPIC_API_KEY=your_key_here` |
| `.gitignore` | Add `.env` |
| `lib/main.dart` | Load dotenv at startup |
| `lib/core/services/vision_identification_service.dart` | New: interface + ToyIdentification model |
| `lib/core/services/claude_vision_service.dart` | New: Claude API implementation |
| `lib/core/services/services_provider.dart` | Add `visionIdentificationServiceProvider` |
| `lib/features/capture/screens/capture_screen.dart` | Add "Identify with AI" button |
| `test/vision_identification_test.dart` | New: unit tests for response parsing |

## Testing

- Unit test: `ToyIdentification.fromJson` parses valid JSON correctly
- Unit test: `ToyIdentification.fromJson` handles missing fields with defaults
- Unit test: unrecognized category defaults to "Other"
- Unit test: invalid JSON falls back to raw text as name
- Widget test: "Identify with AI" button not shown when no API key configured
