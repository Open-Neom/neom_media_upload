import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_upload_firestore.dart';
import 'package:neom_core/data/firestore/post_firestore.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/use_cases/camera_service.dart';
import 'package:neom_core/domain/use_cases/image_editor_service.dart';
import 'package:neom_core/domain/use_cases/media_player_service.dart';
import 'package:neom_core/domain/use_cases/media_upload_service.dart';
import 'package:neom_core/domain/use_cases/post_upload_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_file_from.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/media_type.dart';
import 'package:neom_core/utils/enums/media_upload_destination.dart';
import 'package:neom_core/utils/enums/post_type.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

import '../utils/constants/media_upload_translation_constants.dart';
import '../utils/mappers/file_type_mapper.dart';
import '../utils/media_upload_utilities.dart';

class MediaUploadController extends GetxController implements MediaUploadService {
  
  final userServiceImpl = Get.find<UserService>();
  AppProfile profile = AppProfile();

  final RxBool isLoading = true.obs;
  final RxBool isUploading = false.obs;
  final Rx<File> mediaFile = File("").obs;
  final RxBool takePhoto = false.obs;
  final Rx<FilePickerResult?> _filePickerResult = const FilePickerResult([]).obs;

  @override
  List<File> get releaseFiles => MediaUploadUtilities.convertPlatformFilesToFiles(_filePickerResult.value?.files ?? []);

  final String mediaId = const Uuid().v4();
  File thumbnailFile = File("");
  String _mediaUrl = "";
  String thumbnailUrl = "";

  MediaType mediaType = MediaType.image;

  MediaUploadDestination mediaUploadDestination = MediaUploadDestination.post;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("MediaUploadController Init");
    profile = userServiceImpl.profile;

    try {

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void onReady() {
    super.onReady();

    try {
      isLoading.value = false;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> handleMedia(File file) async {
    AppConfig.logger.t("handleMedia");

    if(file.path.isNotEmpty) {
      mediaType = MediaUploadUtilities.getMediaTypeFromExtension(file);
      AppConfig.logger.d('File is ${mediaType.name}: ${file.path}');

      switch(mediaType) {
        case MediaType.image:
          Get.find<PostUploadService>().setPostType(PostType.image);
          await handleImage(imageFile: file);
        case MediaType.video:
          Get.find<PostUploadService>().setPostType(PostType.video);
          await Get.find<MediaPlayerService>().initializeVideoPlayerController(file);
          await handleVideo(videoFile: file);
        case MediaType.audio:
        case MediaType.document:
        case MediaType.unknown:
        default:
        AppConfig.logger.d('FileType ${mediaType.name} is not supported yet');
          break;
      }

      switch(mediaUploadDestination) {
        case MediaUploadDestination.post:
          takePhoto.value = false;
          Get.toNamed(AppRouteConstants.postUploadDescription);
          break;
      // TODO: Handle each case.
        case MediaUploadDestination.thumbnail:
        case MediaUploadDestination.event:
        case MediaUploadDestination.profile:
        case MediaUploadDestination.cover:
        case MediaUploadDestination.comment:
        case MediaUploadDestination.message:
        case MediaUploadDestination.itemlist:
        case MediaUploadDestination.releaseItem:
        case MediaUploadDestination.sponsor:
        case MediaUploadDestination.ad:
          break;
      }
    } else {
      AppConfig.logger.d('No se seleccionó ningún archivo.');
      return;
    }
  }

  @override
  Future<void> handleImage({AppFileFrom appFileFrom = AppFileFrom.gallery,
    MediaUploadDestination uploadDestination = MediaUploadDestination.post, File? imageFile,
    double ratioX = 1, double ratioY = 1, bool crop = true, BuildContext? context}) async {

    try {

      mediaUploadDestination = uploadDestination;
      mediaFile.value = File((await _getImageFile(
          appFileFrom: appFileFrom, imageFile: imageFile, context: context, ratioX: ratioX, ratioY: ratioY))?.path ?? '');

      if(crop) {
        File? croppedFile = await Get.find<ImageEditorService>().cropImage(mediaFile.value);
        mediaFile.value = croppedFile ?? mediaFile.value;
      }

      if(mediaFile.value.path.isNotEmpty) {
        mediaType = MediaType.image;

        // switch(mediaUploadDestination) {
        //   case MediaUploadDestination.post:
        //     takePhoto.value = false;
        //     Get.toNamed(AppRouteConstants.postUploadDescription);
        //     break;
        //   // TODO: Handle each case.
        //   case MediaUploadDestination.thumbnail:
        //   case MediaUploadDestination.event:
        //   case MediaUploadDestination.profile:
        //   case MediaUploadDestination.cover:
        //   case MediaUploadDestination.comment:
        //   case MediaUploadDestination.message:
        //   case MediaUploadDestination.itemlist:
        //   case MediaUploadDestination.releaseItem:
        //   case MediaUploadDestination.sponsor:
        //   case MediaUploadDestination.ad:
        //     break;
        // }
      }
    }  catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  Future<void> handleVideo({AppFileFrom appFileFrom = AppFileFrom.gallery,
    MediaUploadDestination uploadDestination = MediaUploadDestination.post, File? videoFile}) async {
    AppConfig.logger.d("handleVideo");

    try {
      mediaUploadDestination = uploadDestination;
      mediaFile.value = File((await _getVideoFile(
          appFileFrom: appFileFrom, profileId: profile.id, videoFile: videoFile))?.path ?? '');

      if(mediaFile.value.path.isNotEmpty) {
        mediaType = MediaType.video;
        //TODO: Handle this case whem TRIM & CROP WORKS.
        //Get.to(() => StatefulVideoEditor(file: File(mediaFile.value.path,)));
        setProcessedVideo(File(mediaFile.value.path)); //REMOVE WHEN StatefulVideoEditor is active
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  Future<void> setProcessedVideo(File videoFile) async {
    AppConfig.logger.d("setProcessedVideo");

    try {
      mediaFile.value = videoFile;
      if(mediaFile.value.path.isNotEmpty) {
        mediaType = MediaType.video;
        thumbnailFile = await MediaUploadUtilities.getVideoThumbnail(mediaFile.value);
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  Future<bool> validateMediaSize() async {
    AppConfig.logger.t("validateMediaSize");

    bool isValidSize = true;

    try {

      isValidSize = await MediaUploadUtilities.isValidFileSize(File(mediaFile.value.path), mediaType);

      if(!isValidSize) {
        File compressedFile = File('');

        switch(mediaType) {
          case MediaType.image:

          case MediaType.video:
            AppConfig.logger.w("VideoFile size is above maximum. Starting compression");
            MediaInfo? mediaInfo = await VideoCompress.compressVideo(mediaFile.value.path, quality: VideoQuality.DefaultQuality);
            if(mediaInfo != null) compressedFile = mediaInfo.file!;
          case MediaType.audio:
          case MediaType.document:
          case MediaType.unknown:
          default:
            break;
        }

        isValidSize = await MediaUploadUtilities.isValidFileSize(compressedFile, mediaType);

        if(isValidSize) {
          AppConfig.logger.w("Media File size  is now below limit");
          mediaFile.value = compressedFile;
        } else {
          AppConfig.logger.w("Media File size is still above limit");
          Get.back();
          AppUtilities.showSnackBar(message: MediaUploadTranslationConstants.mediaAboveSizeMsg);
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.upload]);
    return isValidSize;
  }

  @override
  Future<String> uploadFile(MediaUploadDestination uploadDestination) async {
    isUploading.value = true;

    bool isValidSize = await validateMediaSize();

    try {
      if(isValidSize) {
        _mediaUrl = await AppUploadFirestore().uploadMediaFile(mediaId, mediaFile.value, mediaType, uploadDestination);
        AppConfig.logger.d("File ${mediaType.name} uploaded to $mediaUrl");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      AppUtilities.showSnackBar(message: MediaUploadTranslationConstants.mediaUploadErrorMsg.tr);
    }

    return mediaUrl;
  }

  ///THERE IS NO SOLUTION YET TO FRONTAL PHOTO MIRRORED - OCTOBER 2023
  // Future<bool> isFrontCameraPhoto(File imgFile) async {
  //   final exifData = await readExifFromFile(imgFile);
  //   return exifData['LensModel']?.values.toString().contains('front') ?? false;
  // }
  //
  // Future<void> mirrorFrontCameraPhoto(File imgFile) async {
  //   img.Image image = img.decodeImage(imgFile.readAsBytesSync())!;
  //   img.Image mirroredImage = img.copyRotate(image, angle: 180); // Flip the image horizontally
  //
  //   File mirroredImgFile = File('mirrored_image.jpg');
  //   mirroredImgFile.writeAsBytesSync(img.encodeJpg(mirroredImage));
  //   imageFile.value = mirroredImgFile;
  // }

  @override
  Future<File> pickMedia({MediaType type = MediaType.media}) async {
    AppConfig.logger.t("pickMediaFromDevice");

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileTypeMapper.fromMediaType(type),
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) mediaFile.value = File(file.path!);
    }

    if(mediaFile.value.path.isNotEmpty && type == MediaType.media) {
      mediaType = MediaUploadUtilities.getMediaTypeFromExtension(mediaFile.value);

      switch(mediaType) {
        case MediaType.image:
          File? compressedFile = await MediaUploadUtilities.compressImageFile(mediaFile.value);
          if(compressedFile != null) mediaFile.value = compressedFile;
          Get.toNamed(AppRouteConstants.postUploadDescription);
        case MediaType.video:
          Get.toNamed(AppRouteConstants.videoEditor, arguments: [File(mediaFile.value.path)]);
        case MediaType.audio:
        case MediaType.document:
        case MediaType.unknown:
        default:
          break;
      }
    }

    update();
    return mediaFile.value;
  }

  @override
  Future<File> pickMultipleMedia({MediaType type = MediaType.media}) async {
    AppConfig.logger.t("pickMediaFromDevice");

    _filePickerResult.value = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [AppConfig.instance.appInUse == AppInUse.e ? 'pdf':'mp3'],
      allowMultiple: true,
    );

    if (releaseFiles.isNotEmpty) {
      File file = releaseFiles.first;
      mediaFile.value = file;
    }

    if(mediaFile.value.path.isNotEmpty && type == MediaType.media) {
      mediaType = MediaUploadUtilities.getMediaTypeFromExtension(mediaFile.value);

      switch(mediaType) {
        case MediaType.image:
          File? compressedFile = await MediaUploadUtilities.compressImageFile(mediaFile.value);
          if(compressedFile != null) mediaFile.value = compressedFile;
          Get.toNamed(AppRouteConstants.postUploadDescription);
        case MediaType.video:
          Get.toNamed(AppRouteConstants.videoEditor, arguments: [File(mediaFile.value.path)]);
        case MediaType.audio:
        case MediaType.document:
        case MediaType.unknown:
        default:
          break;
      }
    }

    update();
    return mediaFile.value;
  }

  @override
  File getMediaFile() {
    AppConfig.logger.d("getMediaFile: ${mediaFile.value.path}");
    return File(mediaFile.value.path);
  }

  @override
  void setMediaFile(File file) {
    mediaFile.value = file;
  }

  @override
  String getMediaId() {
    AppConfig.logger.d("getMediaFile: ${mediaFile.value.path}");
    return mediaId;
  }

  @override
  Future<void> deleteFileFromUrl(String fileUrl) {
    // TODO: implement deleteFileFromUrl
    throw UnimplementedError();
  }

  Future<File?> _getImageFile({AppFileFrom appFileFrom = AppFileFrom.gallery, File? imageFile,
    double ratioX = 1, double ratioY = 1, BuildContext? context}) async {


    try {

      if(imageFile == null) {
        switch (appFileFrom) {
          case AppFileFrom.gallery:
            imageFile = File((await ImagePicker().pickImage(source: ImageSource.gallery))?.path ?? '');
            break;
          case AppFileFrom.camera:
            AppCameraService appCameraServiceImpl = Get.find<AppCameraService>();
            if(appCameraServiceImpl.isInitialized()) {
              if(context != null) Navigator.pop(context);

              ///THERE IS NO SOLUTION YET TO FRONTAL PHOTO MIRRORED - OCTOBER 2023
              // imageFile.value = await cameraController!.takePicture();
              // bool isFrontal = await isFrontCameraPhoto(File(imageFile.value.path));
              // if(isFrontal) {
              //   mirrorFrontCameraPhoto(File(imageFile.value.path));
              // }
              break;
            } else {
              await appCameraServiceImpl.initializeCameraController();
              if(context != null) Navigator.pop(context);
            }
        }
      }
    }  catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return imageFile;
  }

  Future<File?> _getVideoFile({AppFileFrom appFileFrom = AppFileFrom.gallery, File? videoFile, String profileId = ''}) async {
    AppConfig.logger.d("handleVideo");

    try {

      if(profileId.isNotEmpty && await PostFirestore().isVideoLimitReachedForUser(profileId)) {
        AppUtilities.showSnackBar(
            message: MediaUploadTranslationConstants.maxVideosPerWeekReachedMsg.tr,
            duration: const Duration(seconds: 5)
        );
        return null;
      } else if(videoFile == null) {
        switch (appFileFrom) {
          case AppFileFrom.gallery:
            videoFile = File((await ImagePicker().pickVideo(source: ImageSource.gallery))?.path ?? '');
            break;
          case AppFileFrom.camera:
          ///NOT NEEDED YET
          /// file = (await ImagePicker().pickVideo(source: ImageSource.camera))!;
          /// break;
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return videoFile;
  }


  @override
  void clearMedia(){
    mediaFile.value =  File("");
    mediaType = MediaType.unknown;
  }

  @override
  bool mediaFileExists() {
    return mediaFile.value.path.isNotEmpty;
  }

  @override
  Future<String> uploadThumbnail() async {
    thumbnailUrl = await AppUploadFirestore().uploadMediaFile(mediaId, thumbnailFile, MediaType.image, MediaUploadDestination.thumbnail);
    return thumbnailUrl;
  }

  @override
  String getReleaseFilePath() {

    String releasePath = "";
    _filePickerResult.value;

    try {
      if(Platform.isIOS) {
        PlatformFile? file = _filePickerResult.value?.files.first;
        String uriPath = file?.path ?? "";
        final fileUri = Uri.parse(uriPath);
        releasePath = File.fromUri(fileUri).path;
      } else {
        releasePath = _filePickerResult.value?.paths.first ?? "";
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return releasePath;
  }

  @override
  String get mediaUrl => _mediaUrl;

}
