import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/services_provider.dart';
import '../../categories/providers/categories_provider.dart';
import '../../inventory/providers/inventory_provider.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _imagePath;
  String? _thumbnailPath;
  String _selectedCategory = 'Other';
  List<String> _aiLabels = [];
  bool _isProcessing = false;
  bool _isSaving = false;

  // Lifecycle fields
  String _condition = 'good';
  String? _location;
  String _status = 'active';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryNamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Toy'),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing image...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 24),
                    if (_imagePath != null) ...[
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildDescriptionField(),
                      const SizedBox(height: 16),
                      _buildCategoryDropdown(categories),
                      const SizedBox(height: 16),
                      if (_aiLabels.isNotEmpty) _buildAILabelsSection(),
                      const SizedBox(height: 16),
                      _buildLifecycleSection(),
                      const SizedBox(height: 24),
                      _buildSaveButton(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: _imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(_imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to take a photo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'or choose from gallery',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Toy Name',
        prefixIcon: Icon(Icons.toys),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a name';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (optional)',
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
    );
  }

  Widget _buildCategoryDropdown(List<String> categories) {
    final categoryList = categories.isNotEmpty
        ? categories
        : AppConstants.categoryIcons.keys.toList();

    return DropdownButtonFormField<String>(
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
              Icon(
                AppConstants.getCategoryIcon(category),
                size: 20,
              ),
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
          });
        }
      },
    );
  }

  Widget _buildAILabelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Detected Labels',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _aiLabels.map((label) {
            return Chip(
              label: Text(label),
              avatar: const Icon(Icons.smart_toy, size: 18),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLifecycleSection() {
    return Card(
      child: ExpansionTile(
        title: const Text('Lifecycle Settings'),
        subtitle: Text(
          '${AppConstants.getConditionLabel(_condition)} - ${AppConstants.getStatusLabel(_status)}',
        ),
        leading: const Icon(Icons.settings),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Condition selector
                Text(
                  'Condition',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: AppConstants.conditions.map((condition) {
                      return ButtonSegment<String>(
                        value: condition,
                        label: Text(AppConstants.getConditionLabel(condition)),
                      );
                    }).toList(),
                    selected: {_condition},
                    onSelectionChanged: (Set<String> selected) {
                      setState(() {
                        _condition = selected.first;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Location field
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    prefixIcon: Icon(Icons.location_on),
                    hintText: 'e.g., Bedroom, Toy Box',
                  ),
                  onChanged: (value) {
                    _location = value.isNotEmpty ? value : null;
                  },
                ),
                const SizedBox(height: 16),

                // Status selector
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: AppConstants.statuses.map((status) {
                      return ButtonSegment<String>(
                        value: status,
                        label: Text(AppConstants.getStatusLabel(status)),
                      );
                    }).toList(),
                    selected: {_status},
                    onSelectionChanged: (Set<String> selected) {
                      setState(() {
                        _status = selected.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return FilledButton.icon(
      onPressed: _isSaving ? null : _saveToy,
      icon: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save),
      label: Text(_isSaving ? 'Saving...' : 'Save Toy'),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _captureImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _captureImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Save image and generate thumbnail
      final imageStorage = ref.read(imageStorageServiceProvider);
      final result = await imageStorage.saveImage(File(pickedFile.path));

      // Analyze image with AI
      final aiService = ref.read(aiRecognitionServiceProvider);
      final labels = await aiService.recognizeImage(result.imagePath);
      final suggestedCategory = aiService.suggestCategory(labels);
      final suggestedName = aiService.suggestName(labels);

      setState(() {
        _imagePath = result.imagePath;
        _thumbnailPath = result.thumbnailPath;
        _aiLabels = labels;
        _selectedCategory = suggestedCategory;
        if (_nameController.text.isEmpty) {
          _nameController.text = suggestedName;
        }
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    }
  }

  Future<void> _saveToy() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo first')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(inventoryProvider.notifier).addToy(
            name: _nameController.text,
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
            imagePath: _imagePath!,
            thumbnailPath: _thumbnailPath,
            category: _selectedCategory,
            aiLabels: _aiLabels,
            condition: _condition,
            location: _location,
            status: _status,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving toy: $e')),
        );
      }
    }
  }
}
