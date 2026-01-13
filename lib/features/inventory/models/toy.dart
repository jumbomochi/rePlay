import 'dart:convert';

class ToyModel {
  final int? id;
  final String name;
  final String? description;
  final String imagePath;
  final String? thumbnailPath;
  final String category;
  final List<String> aiLabels;
  final DateTime createdAt;
  final DateTime updatedAt;

  ToyModel({
    this.id,
    required this.name,
    this.description,
    required this.imagePath,
    this.thumbnailPath,
    this.category = 'Other',
    this.aiLabels = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ToyModel copyWith({
    int? id,
    String? name,
    String? description,
    String? imagePath,
    String? thumbnailPath,
    String? category,
    List<String>? aiLabels,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ToyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      category: category ?? this.category,
      aiLabels: aiLabels ?? this.aiLabels,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'thumbnailPath': thumbnailPath,
      'category': category,
      'aiLabels': jsonEncode(aiLabels),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ToyModel.fromMap(Map<String, dynamic> map) {
    return ToyModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      imagePath: map['imagePath'] as String,
      thumbnailPath: map['thumbnailPath'] as String?,
      category: map['category'] as String? ?? 'Other',
      aiLabels: map['aiLabels'] != null
          ? List<String>.from(jsonDecode(map['aiLabels'] as String))
          : [],
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'ToyModel(id: $id, name: $name, category: $category)';
  }
}
