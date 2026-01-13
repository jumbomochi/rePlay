import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class AIRecognitionService {
  ImageLabeler? _labeler;

  Future<void> initialize() async {
    final options = ImageLabelerOptions(confidenceThreshold: 0.5);
    _labeler = ImageLabeler(options: options);
  }

  Future<List<String>> recognizeImage(String imagePath) async {
    if (_labeler == null) {
      await initialize();
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final labels = await _labeler!.processImage(inputImage);

    return labels
        .map((label) => label.label)
        .where((label) => label.isNotEmpty)
        .toList();
  }

  String suggestCategory(List<String> labels) {
    final lowercaseLabels = labels.map((l) => l.toLowerCase()).toList();

    // Map ML Kit labels to our categories
    final categoryMappings = {
      'Action Figures': ['action figure', 'figurine', 'superhero', 'robot', 'soldier', 'warrior'],
      'Dolls': ['doll', 'barbie', 'baby doll', 'fashion doll'],
      'Building Blocks': ['lego', 'building block', 'brick', 'construction toy', 'block'],
      'Vehicles': ['car', 'truck', 'vehicle', 'train', 'airplane', 'boat', 'motorcycle', 'bus'],
      'Puzzles': ['puzzle', 'jigsaw'],
      'Board Games': ['board game', 'game', 'chess', 'cards', 'dice'],
      'Stuffed Animals': ['stuffed animal', 'plush', 'teddy bear', 'soft toy', 'stuffed toy', 'bear', 'animal'],
      'Educational': ['educational', 'learning', 'science', 'math', 'alphabet', 'book'],
      'Outdoor': ['outdoor', 'ball', 'sports', 'bicycle', 'scooter', 'kite'],
    };

    for (final entry in categoryMappings.entries) {
      for (final keyword in entry.value) {
        if (lowercaseLabels.any((label) => label.contains(keyword))) {
          return entry.key;
        }
      }
    }

    return 'Other';
  }

  String suggestName(List<String> labels) {
    if (labels.isEmpty) return 'New Toy';

    // Take the first few relevant labels and create a name
    final relevantLabels = labels.take(2).toList();
    if (relevantLabels.isEmpty) return 'New Toy';

    // Capitalize first letter of each word
    return relevantLabels
        .map((label) => label
            .split(' ')
            .map((word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : '')
            .join(' '))
        .join(' ');
  }

  Future<void> dispose() async {
    await _labeler?.close();
    _labeler = null;
  }
}
