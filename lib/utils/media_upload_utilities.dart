import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/enums/media_type.dart';
import 'package:video_compress/video_compress.dart';

import 'constants/media_upload_constants.dart';

class MediaUploadUtilities {

  static Future<File?> compressImageFile(File imageFile) async {

    File? compressedFile;
    CompressFormat compressFormat = CompressFormat.jpeg;

    try {
      ///DEPRECATED final lastIndex = imageFile.path.lastIndexOf(RegExp(r'.jp'));
      final lastIndex = imageFile.path.lastIndexOf(RegExp(r'\.jp|\.png'));


      if(lastIndex >= 0) {
        String subPath = imageFile.path.substring(0, (lastIndex));
        String fileFormat = imageFile.path.substring(lastIndex);

        if(fileFormat.contains(CompressFormat.png.name)) {
          compressFormat = CompressFormat.png;
        }

        String outPath = "${subPath}_out$fileFormat";
        File result = File((await FlutterImageCompress.compressAndGetFile(imageFile.path, outPath, format: compressFormat))?.path ?? '');

        if(result.path.isNotEmpty ) {
          compressedFile = result;
          AppConfig.logger.d("Image compressed successfully");
        } else {
          AppConfig.logger.w("Image was not compressed and return as before");
        }
      }
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }

    return compressedFile;
  }

  static Future<File> getVideoThumbnail(File videoFile) async {
    AppConfig.logger.d("Getting Video Thumbnail for ${videoFile.path}");

    File thumbnailFile = File("");
    try {
      thumbnailFile = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: CoreConstants.videoQuality,
      );
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("Video Thumbnail created at ${thumbnailFile.path}");
    return thumbnailFile;
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
