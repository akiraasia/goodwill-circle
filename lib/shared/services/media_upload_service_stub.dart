import 'package:goodwill_circle/shared/services/photo_upload_exception.dart';

class MediaUploadService {
  static Future<String?> pickAndUploadImage({required String folder}) async {
    throw const PhotoUploadException(
      'Photo upload is not available on this platform yet.',
    );
  }
}
