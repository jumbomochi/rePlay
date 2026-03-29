import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/database/database.dart';

class PhotoGalleryStrip extends StatelessWidget {
  final String? coverImagePath;
  final String? coverThumbnailPath;
  final List<ToyImage> additionalImages;
  final int selectedIndex;
  final void Function(int index) onThumbnailTap;
  final VoidCallback? onAddPhoto;
  final void Function(int imageId)? onDeletePhoto;
  final int maxPhotos;

  const PhotoGalleryStrip({
    super.key,
    this.coverImagePath,
    this.coverThumbnailPath,
    required this.additionalImages,
    this.selectedIndex = 0,
    required this.onThumbnailTap,
    this.onAddPhoto,
    this.onDeletePhoto,
    this.maxPhotos = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCover = coverImagePath != null && coverImagePath!.isNotEmpty;
    final totalPhotos = additionalImages.length + (hasCover ? 1 : 0);

    if (!hasCover && additionalImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: totalPhotos + (totalPhotos < maxPhotos && onAddPhoto != null ? 1 : 0),
        itemBuilder: (context, index) {
          // Add button at the end
          if (index == totalPhotos) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: onAddPhoto,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 20, color: theme.colorScheme.outline),
                      const SizedBox(height: 2),
                      Text(
                        '$totalPhotos/$maxPhotos',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Cover photo thumbnail (index 0)
          if (hasCover && index == 0) {
            final thumbPath = coverThumbnailPath ?? coverImagePath!;
            return _buildThumbnail(
              context: context,
              imagePath: thumbPath,
              isSelected: selectedIndex == 0,
              onTap: () => onThumbnailTap(0),
              onLongPress: null,
            );
          }

          // Additional photo thumbnails
          final imageIndex = hasCover ? index - 1 : index;
          final image = additionalImages[imageIndex];
          final thumbPath = image.thumbnailPath ?? image.imagePath;
          return _buildThumbnail(
            context: context,
            imagePath: thumbPath,
            isSelected: selectedIndex == index,
            onTap: () => onThumbnailTap(index),
            onLongPress: onDeletePhoto != null
                ? () => onDeletePhoto!(image.id)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildThumbnail({
    required BuildContext context,
    required String imagePath,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
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
                  child: Icon(Icons.image, size: 24, color: Colors.grey[400]),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
