import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../database/database.dart';

class BackupService {
  String exportToJson(List<Toy> toys) {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'toys': toys.map((toy) => {
        'name': toy.name,
        'description': toy.description,
        'category': toy.category,
        'condition': toy.condition,
        'location': toy.location,
        'status': toy.status,
        'owner': toy.owner,
        'aiLabels': toy.aiLabels,
        'createdAt': toy.createdAt.toIso8601String(),
        'updatedAt': toy.updatedAt.toIso8601String(),
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<String> writeBackupFile(List<Toy> toys) async {
    final content = exportToJson(toys);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/replay_backup_$timestamp.json');
    await file.writeAsString(content);
    return file.path;
  }

  List<Map<String, dynamic>> parseImport(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final version = data['version'] as int?;

    if (version == null || version > 1) {
      throw Exception('Unsupported backup version: $version');
    }

    final toys = (data['toys'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return toys.map((toy) {
      return {
        'name': toy['name'] ?? 'Unknown',
        'description': toy['description'],
        'category': toy['category'] ?? 'Other',
        'condition': toy['condition'] ?? 'good',
        'location': toy['location'],
        'status': toy['status'] ?? 'active',
        'owner': toy['owner'],
        'aiLabels': toy['aiLabels'] ?? '[]',
        'createdAt': toy['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': toy['updatedAt'] ?? DateTime.now().toIso8601String(),
      };
    }).toList();
  }

  List<Map<String, dynamic>> filterDuplicates(
    List<Map<String, dynamic>> incoming,
    List<Toy> existing,
  ) {
    final existingKeys = existing
        .map((t) => '${t.name}|${t.createdAt.toIso8601String()}')
        .toSet();

    return incoming.where((toy) {
      final key = '${toy['name']}|${toy['createdAt']}';
      return !existingKeys.contains(key);
    }).toList();
  }
}
