import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ImageStorageService {
  static const _uuid = Uuid();
  static const _imagesFolder = 'toy_images';
  static const _thumbnailSize = 300;

  Future<String> _getImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, _imagesFolder));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir.path;
  }

  Future<({String imagePath, String thumbnailPath})> saveImage(File imageFile) async {
    final imagesDir = await _getImagesDirectory();
    final uniqueId = _uuid.v4();
    final extension = p.extension(imageFile.path).isNotEmpty
        ? p.extension(imageFile.path)
        : '.jpg';

    // Save full image
    final imagePath = p.join(imagesDir, '$uniqueId$extension');
    await imageFile.copy(imagePath);

    // Generate and save thumbnail
    final thumbnailPath = p.join(imagesDir, '${uniqueId}_thumb$extension');
    await _generateThumbnail(imagePath, thumbnailPath);

    return (imagePath: imagePath, thumbnailPath: thumbnailPath);
  }

  Future<({String imagePath, String thumbnailPath})> saveImageFromBytes(
    Uint8List bytes, {
    String extension = '.jpg',
  }) async {
    final imagesDir = await _getImagesDirectory();
    final uniqueId = _uuid.v4();

    // Save full image
    final imagePath = p.join(imagesDir, '$uniqueId$extension');
    await File(imagePath).writeAsBytes(bytes);

    // Generate and save thumbnail
    final thumbnailPath = p.join(imagesDir, '${uniqueId}_thumb$extension');
    await _generateThumbnail(imagePath, thumbnailPath);

    return (imagePath: imagePath, thumbnailPath: thumbnailPath);
  }

  Future<void> _generateThumbnail(String sourcePath, String destPath) async {
    final sourceFile = File(sourcePath);
    final bytes = await sourceFile.readAsBytes();

    final image = img.decodeImage(bytes);
    if (image == null) return;

    final thumbnail = img.copyResize(
      image,
      width: image.width > image.height ? _thumbnailSize : null,
      height: image.height >= image.width ? _thumbnailSize : null,
      interpolation: img.Interpolation.linear,
    );

    final thumbnailBytes = img.encodeJpg(thumbnail, quality: 85);
    await File(destPath).writeAsBytes(thumbnailBytes);
  }

  Future<void> deleteImage(String imagePath, {String? thumbnailPath}) async {
    final imageFile = File(imagePath);
    if (await imageFile.exists()) {
      await imageFile.delete();
    }

    if (thumbnailPath != null) {
      final thumbFile = File(thumbnailPath);
      if (await thumbFile.exists()) {
        await thumbFile.delete();
      }
    }
  }

  Future<bool> imageExists(String imagePath) async {
    return File(imagePath).exists();
  }
}
