class MediaUploadConstants {

  /// Max allowed file sizes after compression
  static const int maxImageFileSize = 10 * 1024 * 1024; // 10 MB
  static const int maxVideoFileSize = 100 * 1024 * 1024; // 100 MB
  static const int maxAudioFileSize = 25 * 1024 * 1024; // 25 MB
  static const int maxPdfFileSize = 20 * 1024 * 1024; // 20 MB

  /// Proactive compression thresholds — compress if file exceeds this size
  /// even if it's under the max limit, to save bandwidth and storage.
  static const int videoCompressionThreshold = 5 * 1024 * 1024; // 5 MB — compress any video > 5MB

}
