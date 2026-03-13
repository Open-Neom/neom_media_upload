import 'dart:typed_data';

import 'package:neom_core/utils/platform/core_io.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_upload_firestore.dart';
import 'package:neom_core/domain/use_cases/media_upload_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/enums/app_file_from.dart';
import 'package:neom_core/utils/enums/media_type.dart';
import 'package:neom_core/utils/enums/media_upload_destination.dart';
import 'package:sint/sint.dart';
import 'package:uuid/uuid.dart';

import '../utils/constants/media_upload_constants.dart';
import '../utils/constants/media_upload_translation_constants.dart';
import '../utils/mappers/file_type_mapper.dart';

/// Web implementation of [MediaUploadService].
///
/// Uses [FilePicker] with `withData: true` to get file bytes directly
/// (since dart:io File operations don't work on web).
/// Uploads via [AppUploadFirestore.uploadMediaBytes] using Uint8List.
class MediaUploadWebController extends SintController implements MediaUploadService {

  final userServiceImpl = Sint.find<UserService>();

  /// Internal state — bytes-based instead of File-based
  Uint8List? _mediaBytes;
  String _fileName = '';
  String _mediaId = const Uuid().v4();
  MediaType _mediaType = MediaType.unknown;
  String _mediaUrl = '';
  MediaUploadDestination _uploadDestination = MediaUploadDestination.post;

  /// For multiple file picks (releases)
  List<PlatformFile> _releasePickedFiles = [];

  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t('MediaUploadWebController Init');
  }

  // ─── Picking ───

  @override
  Future<File> pickMedia({MediaType type = MediaType.media}) async {
    AppConfig.logger.t('pickMedia (web)');

    final result = await FilePicker.platform.pickFiles(
      type: FileTypeMapper.fromMediaType(type),
      withData: true,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final picked = result.files.first;
      _setFromPlatformFile(picked);
    }

    update();
    return File(_fileName);
  }

  @override
  Future<File> pickMultipleMedia({MediaType type = MediaType.media}) async {
    AppConfig.logger.t('pickMultipleMedia (web)');

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp3'],
      withData: true,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      _releasePickedFiles = result.files;
      _setFromPlatformFile(result.files.first);
    }

    update();
    return File(_fileName);
  }

  // ─── Handling ───

  @override
  Future<void> handleMedia(File file) async {
    AppConfig.logger.t('handleMedia (web) — using file_picker instead');
    // On web, File objects from other sources won't have real data.
    // If bytes are already set (from pickMedia), just detect the type.
    if (_mediaBytes != null && _fileName.isNotEmpty) {
      _mediaType = _getMediaTypeFromName(_fileName);
    }
  }

  @override
  Future<void> handleImage({
    AppFileFrom appFileFrom = AppFileFrom.gallery,
    MediaUploadDestination uploadDestination = MediaUploadDestination.post,
    File? imageFile,
    double ratioX = 1,
    double ratioY = 1,
    bool crop = true,
    BuildContext? context,
  }) async {
    AppConfig.logger.t('handleImage (web)');
    _uploadDestination = uploadDestination;

    // If no bytes loaded yet, open file picker
    if (_mediaBytes == null || _mediaBytes!.isEmpty) {
      await pickMedia(type: MediaType.image);
    }

    if (_mediaBytes != null && _mediaBytes!.isNotEmpty) {
      _mediaType = MediaType.image;
      // No crop on web (first version)
    }
  }

  @override
  Future<void> handleVideo({
    AppFileFrom appFileFrom = AppFileFrom.gallery,
    File? videoFile,
  }) async {
    AppConfig.logger.t('handleVideo (web)');

    if (_mediaBytes == null || _mediaBytes!.isEmpty) {
      await pickMedia(type: MediaType.video);
    }

    if (_mediaBytes != null && _mediaBytes!.isNotEmpty) {
      _mediaType = MediaType.video;
      // No thumbnail generation on web (first version)
    }
  }

  @override
  Future<void> setProcessedVideo(File videoFile) async {
    // No-op on web — no video processing
    AppConfig.logger.t('setProcessedVideo (web) — no-op');
  }

  // ─── Upload ───

  @override
  Future<String> uploadFile(MediaUploadDestination uploadDestination) async {
    AppConfig.logger.t('uploadFile (web)');
    isUploading.value = true;

    try {
      if (_mediaBytes == null || _mediaBytes!.isEmpty) {
        AppConfig.logger.w('No media bytes to upload');
        return '';
      }

      if (!_isValidSize(_mediaBytes!.length, _mediaType)) {
        AppUtilities.showSnackBar(
          message: MediaUploadTranslationConstants.mediaAboveSizeMsg.tr,
        );
        return '';
      }

      _mediaUrl = await AppUploadFirestore().uploadMediaBytes(
        _mediaId,
        _mediaBytes!,
        _mediaType,
        uploadDestination,
      );

      AppConfig.logger.d('File uploaded (web): $_mediaUrl');
    } catch (e) {
      AppConfig.logger.e('Upload error (web): $e');
      AppUtilities.showSnackBar(
        message: MediaUploadTranslationConstants.mediaUploadErrorMsg.tr,
      );
    } finally {
      isUploading.value = false;
    }

    return _mediaUrl;
  }

  @override
  Future<String> uploadThumbnail() async {
    // No thumbnail generation on web
    return '';
  }

  @override
  Future<void> deleteFileFromUrl(String fileUrl) async {
    // Not implemented
  }

  // ─── Getters / Setters ───

  @override
  File getMediaFile() {
    // Return a stub File with the filename for compatibility.
    // On web, dart:io File is a stub — path-based operations work
    // but I/O operations don't. Consumers should use mediaBytes for display.
    return File(_fileName);
  }

  @override
  void setMediaFile(File file) {
    AppConfig.logger.t('setMediaFile (web) — limited support');
    _fileName = file.path;
    _mediaType = _getMediaTypeFromName(_fileName);
  }

  @override
  String getMediaId() => _mediaId;

  @override
  void clearMedia() {
    _mediaBytes = null;
    _fileName = '';
    _mediaId = const Uuid().v4();
    _mediaType = MediaType.unknown;
    _mediaUrl = '';
    _releasePickedFiles = [];
    update();
  }

  @override
  bool mediaFileExists() => _mediaBytes != null && _mediaBytes!.isNotEmpty;

  @override
  String getReleaseFilePath() => _fileName;

  @override
  List<File> get releaseFiles => _releasePickedFiles
      .where((f) => f.bytes != null)
      .map((f) => File(f.name))
      .toList();

  @override
  String get mediaUrl => _mediaUrl;

  @override
  MediaType get mediaType => _mediaType;

  @override
  Uint8List? get mediaBytes => _mediaBytes;

  @override
  Uint8List? getReleaseFileBytes(int index) {
    if (index < 0 || index >= _releasePickedFiles.length) return null;
    return _releasePickedFiles[index].bytes;
  }

  @override
  String getReleaseFileName(int index) {
    if (index >= 0 && index < _releasePickedFiles.length) {
      return _releasePickedFiles[index].name;
    }
    return '';
  }

  // ─── Internal helpers ───

  void _setFromPlatformFile(PlatformFile picked) {
    _mediaBytes = picked.bytes;
    _fileName = picked.name;
    _mediaType = _getMediaTypeFromName(_fileName);
    _mediaId = const Uuid().v4();
    AppConfig.logger.d('Web file picked: $_fileName (${_mediaBytes?.length ?? 0} bytes, type: ${_mediaType.name})');
  }

  MediaType _getMediaTypeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (CoreConstants.imageExtensions.contains(ext)) return MediaType.image;
    if (CoreConstants.videoExtensions.contains(ext)) return MediaType.video;
    if (CoreConstants.audioExtensions.contains(ext)) return MediaType.audio;
    if (CoreConstants.documentExtensions.contains(ext)) return MediaType.document;
    return MediaType.unknown;
  }

  bool _isValidSize(int sizeInBytes, MediaType type) {
    switch (type) {
      case MediaType.image:
        return sizeInBytes < MediaUploadConstants.maxImageFileSize;
      case MediaType.video:
        return sizeInBytes < MediaUploadConstants.maxVideoFileSize;
      case MediaType.audio:
        return sizeInBytes < MediaUploadConstants.maxAudioFileSize;
      case MediaType.document:
        return sizeInBytes < MediaUploadConstants.maxPdfFileSize;
      default:
        return true;
    }
  }

}
