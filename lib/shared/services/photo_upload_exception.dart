class PhotoUploadException implements Exception {
  final String message;

  const PhotoUploadException(this.message);

  @override
  String toString() => message;
}
