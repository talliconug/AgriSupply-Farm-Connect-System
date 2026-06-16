import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _supabase = Supabase.instance.client;

  /// Upload image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadImage({
    required final File imageFile,
    required final String bucket,
    required final String path,
  }) async {
    try {
      // Generate unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
      final filePath = '$path/$fileName';

      // Upload file
      await _supabase.storage.from(bucket).upload(
            filePath,
            imageFile,
          );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required final List<File> imageFiles,
    required final String bucket,
    required final String path,
  }) async {
    final urls = <String>[];

    for (final file in imageFiles) {
      final url = await uploadImage(
        imageFile: file,
        bucket: bucket,
        path: path,
      );
      urls.add(url);
    }

    return urls;
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture({
    required final File imageFile,
    required final String userId,
  }) async {
    return uploadImage(
      imageFile: imageFile,
      bucket: 'profile-photos',
      path: userId,
    );
  }

  /// Upload product images
  Future<List<String>> uploadProductImages({
    required final List<File> imageFiles,
    required final String productId,
  }) async {
    return uploadMultipleImages(
      imageFiles: imageFiles,
      bucket: 'product-images',
      path: productId,
    );
  }

  /// Delete image from storage
  Future<void> deleteImage({
    required final String bucket,
    required final String path,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Delete multiple images
  Future<void> deleteMultipleImages({
    required final String bucket,
    required final List<String> paths,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove(paths);
    } catch (e) {
      throw Exception('Failed to delete images: $e');
    }
  }

  /// Extract file path from public URL
  String getPathFromUrl(final String url, final String bucket) {
    final uri = Uri.parse(url);
    final path = uri.path.split('/').last;
    return path;
  }
}
