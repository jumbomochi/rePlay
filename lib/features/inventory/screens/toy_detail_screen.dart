import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../categories/providers/categories_provider.dart';
import '../providers/inventory_provider.dart';

class ToyDetailScreen extends ConsumerStatefulWidget {
  final int toyId;

  const ToyDetailScreen({super.key, required this.toyId});

  @override
  ConsumerState<ToyDetailScreen> createState() => _ToyDetailScreenState();
}

class _ToyDetailScreenState extends ConsumerState<ToyDetailScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Other';
  bool _hasChanges = false;

  // Lifecycle fields
  String _condition = 'good';
  String? _location;
  String _status = 'active';
  final _locationController = TextEditingController();
  bool _lifecycleExpanded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toyAsync = ref.watch(toyByIdProvider(widget.toyId));
    final categories = ref.watch(categoryNamesProvider);

    return toyAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
      data: (toy) {
        if (toy == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Toy not found')),
          );
        }

        // Initialize controllers if not editing
        if (!_isEditing) {
          _nameController.text = toy.name;
          _descriptionController.text = toy.description ?? '';
          _selectedCategory = toy.category;
          _condition = toy.condition;
          _location = toy.location;
          _locationController.text = toy.location ?? '';
          _status = toy.status;
        }

        final aiLabels = _parseAiLabels(toy.aiLabels);

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Toy' : toy.name),
            actions: [
              if (_isEditing)
                TextButton(
                  onPressed: _cancelEdit,
                  child: const Text('Cancel'),
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditing = true),
                ),
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteDialog(toy.name),
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImage(toy.imagePath),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isEditing
                      ? _buildEditForm(categories)
                      : _buildDetails(toy, aiLabels),
                ),
              ],
            ),
          ),
          floatingActionButton: _isEditing
              ? FloatingActionButton.extended(
                  onPressed: _hasChanges ? _saveChanges : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                )
              : null,
        );
      },
    );
  }

  List<String> _parseAiLabels(String? labelsJson) {
    if (labelsJson == null || labelsJson.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(labelsJson));
    } catch (e) {
      return [];
    }
  }

  Widget _buildImage(String imagePath) {
    return AspectRatio(
      aspectRatio: 1,
      child: FutureBuilder<bool>(
        future: File(imagePath).exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              File(imagePath),
              fit: BoxFit.cover,
            );
          }
          return Container(
            color: Colors.grey[200],
            child: Icon(
              Icons.toys,
              size: 80,
              color: Colors.grey[400],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetails(dynamic toy, List<String> aiLabels) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category
        Row(
          children: [
            Icon(
              AppConstants.getCategoryIcon(toy.category),
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              toy.category,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Description
        if (toy.description != null && toy.description.isNotEmpty) ...[
          Text(
            'Description',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            toy.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],

        // AI Labels
        if (aiLabels.isNotEmpty) ...[
          Text(
            'AI Detected Labels',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: aiLabels.map((label) {
              return Chip(
                label: Text(label),
                avatar: const Icon(Icons.smart_toy, size: 18),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Added date
        Text(
          'Added on ${_formatDate(toy.createdAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(List<String> categories) {
    final categoryList = categories.isNotEmpty
        ? categories
        : AppConstants.categoryIcons.keys.toList();

    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            prefixIcon: Icon(Icons.toys),
          ),
          onChanged: (_) => setState(() => _hasChanges = true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
          onChanged: (_) => setState(() => _hasChanges = true),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
            prefixIcon: Icon(Icons.category),
          ),
          items: categoryList.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Row(
                children: [
                  Icon(AppConstants.getCategoryIcon(category), size: 20),
                  const SizedBox(width: 8),
                  Text(category),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
                _hasChanges = true;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        _buildLifecycleSection(),
      ],
    );
  }

  Widget _buildLifecycleSection() {
    return ExpansionTile(
      initiallyExpanded: _lifecycleExpanded,
      onExpansionChanged: (expanded) {
        setState(() => _lifecycleExpanded = expanded);
      },
      title: const Text('Lifecycle'),
      leading: const Icon(Icons.autorenew),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Condition selector
              const Text(
                'Condition',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: AppConstants.conditions.map((condition) {
                    return ButtonSegment<String>(
                      value: condition,
                      label: Text(
                        AppConstants.getConditionLabel(condition),
                        style: const TextStyle(fontSize: 11),
                      ),
                      icon: Icon(AppConstants.getConditionIcon(condition), size: 16),
                    );
                  }).toList(),
                  selected: {_condition},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _condition = selection.first;
                      _hasChanges = true;
                    });
                  },
                  showSelectedIcon: false,
                ),
              ),
              const SizedBox(height: 16),

              // Location text field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Playroom shelf, Garage bin 2',
                  prefixIcon: Icon(Icons.location_on),
                ),
                onChanged: (value) {
                  setState(() {
                    _location = value.isNotEmpty ? value : null;
                    _hasChanges = true;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Status selector
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: AppConstants.statuses.map((status) {
                    return ButtonSegment<String>(
                      value: status,
                      label: Text(
                        AppConstants.getStatusLabel(status),
                        style: const TextStyle(fontSize: 10),
                      ),
                      icon: Icon(AppConstants.getStatusIcon(status), size: 16),
                    );
                  }).toList(),
                  selected: {_status},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _status = selection.first;
                      _hasChanges = true;
                    });
                  },
                  showSelectedIcon: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _hasChanges = false;
    });
  }

  Future<void> _saveChanges() async {
    final success = await ref.read(inventoryProvider.notifier).updateToy(
          id: widget.toyId,
          name: _nameController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          category: _selectedCategory,
          condition: _condition,
          location: _location,
          status: _status,
        );

    if (success && mounted) {
      setState(() {
        _isEditing = false;
        _hasChanges = false;
      });
      ref.invalidate(toyByIdProvider(widget.toyId));
    }
  }

  void _showDeleteDialog(String toyName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Toy'),
          content: Text('Are you sure you want to delete "$toyName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteToy();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteToy() async {
    final success =
        await ref.read(inventoryProvider.notifier).deleteToy(widget.toyId);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
