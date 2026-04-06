import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database.dart';

class ToyListItem extends StatelessWidget {
  final Toy toy;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isMultiSelectMode;

  const ToyListItem({super.key, required this.toy, this.onTap, this.onLongPress, this.isSelected = false, this.isMultiSelectMode = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbPath = toy.thumbnailPath ?? toy.imagePath;
    return ListTile(
      leading: SizedBox(width: 48, height: 48, child: ClipRRect(borderRadius: BorderRadius.circular(6), child: FutureBuilder<bool>(future: File(thumbPath).exists(), builder: (context, snapshot) { if (snapshot.data == true) return Image.file(File(thumbPath), fit: BoxFit.cover); return Container(color: Colors.grey[200], child: Icon(Icons.toys, size: 24, color: Colors.grey[400])); }))),
      title: Text(toy.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(children: [
        Icon(AppConstants.getCategoryIcon(toy.category), size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(toy.category, style: theme.textTheme.bodySmall),
        if (toy.owner != null && toy.owner!.isNotEmpty) ...[const SizedBox(width: 8), Icon(Icons.person, size: 14, color: theme.colorScheme.onSurfaceVariant), const SizedBox(width: 2), Text(toy.owner!, style: theme.textTheme.bodySmall)],
      ]),
      trailing: isMultiSelectMode ? Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline) : Text(AppConstants.getConditionLabel(toy.condition), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      selected: isSelected && isMultiSelectMode,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
