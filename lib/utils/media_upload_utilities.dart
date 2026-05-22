import 'package:neom_core/utils/platform/core_io.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/enums/media_type.dart';
import 'package:video_compress/video_compress.dart';

import 'constants/media_upload_constants.dart';

class MediaUploadUtilities {

  /// Compresses an image file with quality and resize.
  /// [quality] — JPEG quality 0-100 (default: CoreConstants.imageQuality = 80).
  /// [maxWidth] / [maxHeight] — resize to fit within these bounds (default: 1920).
  static Future<File?> compressImageFile(File imageFile, {
    int quality = CoreConstants.imageQuality,
    int maxWidth = CoreConstants.imageMaxWidth,
    int maxHeight = CoreConstants.imageMaxHeight,
  }) async {

    File? compressedFile;
    CompressFormat compressFormat = CompressFormat.jpeg;

    try {
      final originalSize = await imageFile.length();
      final lastIndex = imageFile.path.lastIndexOf(RegExp(r'\.jp|\.png'));

      if(lastIndex >= 0) {
        String subPath = imageFile.path.substring(0, (lastIndex));
        String fileFormat = imageFile.path.substring(lastIndex);

        if(fileFormat.contains(CompressFormat.png.name)) {
          compressFormat = CompressFormat.png;
        }

        String outPath = "${subPath}_out$fileFormat";
        File result = File((await FlutterImageCompress.compressAndGetFile(
          imageFile.path, outPath,
          format: compressFormat,
          quality: quality,
          minWidth: maxWidth,
          minHeight: maxHeight,
        ))?.path ?? '');

        if(result.path.isNotEmpty) {
          final compressedSize = await result.length();
          final reduction = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);
          compressedFile = result;
          AppConfig.logger.d("Image compressed: ${_formatBytes(originalSize)} -> ${_formatBytes(compressedSize)} ($reduction% reduction)");
        } else {
          AppConfig.logger.w("Image was not compressed and returned as before");
        }
      }
    } catch(e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_media_upload', operation: 'compressImageFile');
    }

    return compressedFile;
  }

  /// Compresses a profile/avatar image with smaller dimensions.
  static Future<File?> compressProfileImage(File imageFile) async {
    return compressImageFile(
      imageFile,
      quality: CoreConstants.imageQuality,
      maxWidth: CoreConstants.profileImageMaxWidth,
      maxHeight: CoreConstants.profileImageMaxHeight,
    );
  }

  /// Compresses a thumbnail image with lower quality.
  static Future<File?> compressThumbnail(File imageFile) async {
    return compressImageFile(
      imageFile,
      quality: CoreConstants.thumbnailQuality,
      maxWidth: 480,
      maxHeight: 480,
    );
  }

  static Future<File> getVideoThumbnail(File videoFile) async {
    AppConfig.logger.d("Getting Video Thumbnail for ${videoFile.path}");

    File thumbnailFile = File("");
    try {
      final dartIoThumbnail = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: CoreConstants.videoThumbnailQuality,
      );
      thumbnailFile = File(dartIoThumbnail.path);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_media_upload', operation: 'getVideoThumbnail');
    }

    AppConfig.logger.d("Video Thumbnail created at ${thumbnailFile.path}");
    return thumbnailFile;
  }

  /// Format bytes to human-readable string (e.g., "2.5 MB").
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static Future<bool> isValidFileSize(File mediaFile, MediaType mediaType) async {
    AppConfig.logger.d("Checking file size for ${mediaFile.path} of type $mediaType");

    try {
      int fileSize = await mediaFile.length();

      switch(mediaType) {
        case MediaType.image:
          return fileSize < MediaUploadConstants.maxImageFileSize;
        case MediaType.video:
         return fileSize < MediaUploadConstants.maxVideoFileSize;
        case MediaType.audio:
          return fileSize < MediaUploadConstants.maxAudioFileSize;
        case MediaType.document:
          return fileSize < MediaUploadConstants.maxPdfFileSize;
        case MediaType.unknown:
          AppConfig.logger.w("Unknown media type for file ${mediaFile.path}");
        default:
          break;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_media_upload', operation: 'isValidFileSize');
    }

    return false;
  }

  static MediaType getMediaTypeFromExtension(File file) {
    AppConfig.logger.d("Determining media type for file: ${file.path}");

    final String extension = file.path.split('.').last.toLowerCase();

    if (CoreConstants.imageExtensions.contains(extension)) {
      return MediaType.image;
    } else if (CoreConstants.videoExtensions.contains(extension)) {
      return MediaType.video;
    } else if (CoreConstants.audioExtensions.contains(extension)) {
      return MediaType.audio;
    } else if (CoreConstants.documentExtensions.contains(extension)) {
      return MediaType.document;
    } else {
      AppConfig.logger.w("Tipo de archivo no soportado por extensión: $extension");
      return MediaType.unknown;
    }
  }

  static File? convertPlatformFileToFile(PlatformFile? platformFile) {
    if (platformFile == null || platformFile.path == null || platformFile.path!.isEmpty) {
      AppConfig.logger.w("PlatformFile is null or has no valid path.");
      return null;
    }
    return File(platformFile.path!);
  }

  static List<File> convertPlatformFilesToFiles(List<PlatformFile>? platformFiles) {
    if (platformFiles == null || platformFiles.isEmpty) {
      return [];
    }

    List<File> files = [];
    for (var platformFile in platformFiles) {
      final File? file = convertPlatformFileToFile(platformFile);
      if (file != null) {
        files.add(file);
      }
    }
    return files;
  }

}
