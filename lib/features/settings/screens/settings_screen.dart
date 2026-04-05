import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/services_provider.dart';
import '../../inventory/providers/inventory_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Export Backup'),
            subtitle: const Text('Save toy inventory as JSON file'),
            onTap: () => _exportBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Backup'),
            subtitle: const Text('Restore toys from a JSON backup file'),
            onTap: () => _importBackup(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final inventoryState = ref.read(inventoryProvider);
    final backupService = ref.read(backupServiceProvider);

    if (inventoryState.toys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No toys to export')),
      );
      return;
    }

    final filePath = await backupService.writeBackupFile(inventoryState.toys);
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'rePlay Backup',
    );
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path;
    if (filePath == null) return;

    try {
      final content = await File(filePath).readAsString();
      final backupService = ref.read(backupServiceProvider);
      final db = ref.read(databaseProvider);

      final incoming = backupService.parseImport(content);
      final existingToys = await db.getAllToys();
      final newToys = backupService.filterDuplicates(incoming, existingToys);

      int imported = 0;
      for (final toyData in newToys) {
        await db.insertToy(ToysCompanion.insert(
          name: toyData['name'] as String,
          description: Value(toyData['description'] as String?),
          imagePath: '',
          category: Value(toyData['category'] as String),
          aiLabels: Value(toyData['aiLabels'] as String),
          condition: Value(toyData['condition'] as String),
          location: Value(toyData['location'] as String?),
          status: Value(toyData['status'] as String),
          owner: Value(toyData['owner'] as String?),
        ));
        imported++;
      }

      await ref.read(inventoryProvider.notifier).refresh();

      if (context.mounted) {
        final skipped = incoming.length - imported;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $imported toys ($skipped skipped as duplicates)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: ${e.toString()}')),
        );
      }
    }
  }
}
