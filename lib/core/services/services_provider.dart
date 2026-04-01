import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_recognition_service.dart';
import 'claude_vision_service.dart';
import 'export_service.dart';
import 'image_storage_service.dart';

final imageStorageServiceProvider = Provider<ImageStorageService>((ref) {
  return ImageStorageService();
});

final aiRecognitionServiceProvider = Provider<AIRecognitionService>((ref) {
  final service = AIRecognitionService();
  ref.onDispose(() => service.dispose());
  return service;
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

final visionIdentificationServiceProvider = Provider<ClaudeVisionService>((ref) {
  return ClaudeVisionService();
});
