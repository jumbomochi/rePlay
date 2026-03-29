import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../database/database.dart';

class ExportService {
  String generateTextList(List<Toy> toys, String filterLabel) {
    final buffer = StringBuffer();
    buffer.writeln('rePlay Toy List ($filterLabel — ${toys.length} toys)');
    buffer.writeln();

    for (var i = 0; i < toys.length; i++) {
      final toy = toys[i];
      final conditionLabel = AppConstants.getConditionLabel(toy.condition);
      final parts = <String>[
        '${i + 1}. ${toy.name}',
        conditionLabel,
      ];
      if (toy.location != null && toy.location!.isNotEmpty) {
        parts.add(toy.location!);
      }
      buffer.writeln(parts.join(' — '));
    }

    return buffer.toString().trimRight();
  }

  String generateCsvContent(List<Toy> toys) {
    final buffer = StringBuffer();
    buffer.writeln('Name,Category,Condition,Location,Status,Date Added');

    for (final toy in toys) {
      final name = _csvEscape(toy.name);
      final category = _csvEscape(toy.category);
      final condition = _csvEscape(AppConstants.getConditionLabel(toy.condition));
      final location = _csvEscape(toy.location ?? '');
      final status = _csvEscape(AppConstants.getStatusLabel(toy.status));
      final date =
          '${toy.createdAt.year}-${toy.createdAt.month.toString().padLeft(2, '0')}-${toy.createdAt.day.toString().padLeft(2, '0')}';
      buffer.writeln('$name,$category,$condition,$location,$status,$date');
    }

    return buffer.toString().trimRight();
  }

  Future<String> writeCsvFile(List<Toy> toys) async {
    final content = generateCsvContent(toys);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/replay_export_$timestamp.csv');
    await file.writeAsString(content);
    return file.path;
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
