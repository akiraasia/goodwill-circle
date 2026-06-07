// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:goodwill_circle/shared/services/photo_upload_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaUploadService {
  static Future<String?> pickAndUploadImage({required String folder}) async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = false;
    input.click();

    await input.onChange.first;
    final file = input.files?.first;
    if (file == null) return null;

    final reader = html.FileReader()..readAsArrayBuffer(file);
    await reader.onLoad.first;
    final bytes = Uint8List.view(reader.result as ByteBuffer);
    final extension = _extensionFor(file.name);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw const PhotoUploadException(
        'Please sign in before uploading a photo.',
      );
    }
    final path =
        '$folder/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    try {
      await Supabase.instance.client.storage
          .from('goodwill-media')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: file.type.isEmpty
                  ? _contentType(extension)
                  : file.type,
              upsert: false,
            ),
          );
    } on StorageException catch (e) {
      throw PhotoUploadException(_friendlyStorageMessage(e.message));
    } catch (_) {
      throw const PhotoUploadException(
        'Could not upload the photo. Re-apply week7_schema.sql in Supabase and try again.',
      );
    }

    return Supabase.instance.client.storage
        .from('goodwill-media')
        .getPublicUrl(path);
  }

  static String _extensionFor(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return 'jpg';
    final extension = parts.last.toLowerCase();
    return extension.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String _contentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  static String _friendlyStorageMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('bucket') || normalized.contains('not found')) {
      return 'Photo storage bucket is missing. Apply week7_schema.sql in Supabase.';
    }
    if (normalized.contains('policy') ||
        normalized.contains('row-level') ||
        normalized.contains('permission') ||
        normalized.contains('forbidden') ||
        normalized.contains('unauthorized')) {
      return 'Photo upload is blocked by Supabase Storage policy. Re-apply week7_schema.sql.';
    }
    return message;
  }
}
