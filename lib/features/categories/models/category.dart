class CategoryModel {
  final int? id;
  final String name;
  final String? iconName;
  final int sortOrder;

  CategoryModel({
    this.id,
    required this.name,
    this.iconName,
    this.sortOrder = 0,
  });

  CategoryModel copyWith({
    int? id,
    String? name,
    String? iconName,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'sortOrder': sortOrder,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconName: map['iconName'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }

  @override
  String toString() => 'CategoryModel(id: $id, name: $name)';
}
