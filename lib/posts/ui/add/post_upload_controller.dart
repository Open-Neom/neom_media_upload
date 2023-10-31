import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hashtagable_v3/functions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neom_commons/core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_commons/core/data/firestore/app_upload_firestore.dart';
import 'package:neom_commons/core/data/firestore/hashtag_firestore.dart';
import 'package:neom_commons/core/data/firestore/post_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/implementations/geolocator_controller.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/hashtag.dart';
import 'package:neom_commons/core/domain/model/post.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_file_from.dart';
import 'package:neom_commons/core/utils/enums/post_type.dart';
import 'package:neom_commons/core/utils/enums/push_notification_type.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';
import 'package:neom_timeline/neom_timeline.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../../domain/use_cases/post_upload_service.dart';
import '../widgets/stateful_video_editor.dart';

class PostUploadController extends GetxController implements PostUploadService {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();
  AppProfile profile = AppProfile();
  Post _post = Post();
  Position? _position;

  final RxBool isButtonDisabled = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final Rx<XFile> mediaFile = XFile("").obs;
  final Rx<File> croppedImageFile = File("").obs;
  final Rx<File> trimmedMediaFile = File("").obs;
  final RxList<String> locationSuggestions = <String>[].obs;
  final RxString caption = "".obs;
  final RxBool takePhoto = false.obs;
  final RxBool cameraControllerDisposed = false.obs;

  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  VideoPlayerController videoPlayerController = VideoPlayerController.networkUrl(Uri());
  CameraController? cameraController;
  List<CameraDescription> cameras = [];

  final _mediaId = const Uuid().v4();
  File _file = File("");
  File _thumbnailFile = File("");
  String mediaUrl = "";
  String thumbnailUrl = "";

  PostType postType = PostType.pending;

  // final Rx<Trimmer> trimmer = Trimmer().obs;
  final RxDouble trimmedStartValue = 0.0.obs;
  final RxDouble trimmedEndValue = 0.0.obs;
  final RxBool isPlaying = false.obs;



  @override
  Future<void> onInit() async {
    super.onInit();
    logger.t("PostUpload Controller Init");
    profile = userController.profile;

    try {
      if(profile.position != null) {
        String profileLocation = await GeoLocatorController().getAddressSimple(profile.position!);
        locationSuggestions.value.add(profileLocation);
        _position = await GeoLocatorController().getCurrentPosition();

        if(_position != null) {
          String currentPosition = await GeoLocatorController().getAddressSimple(_position!);
          if(!locationSuggestions.value.contains(currentPosition)) {
            locationSuggestions.value.add(currentPosition);
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    clearMedia();
  }

  @override
  void onReady() async {
    super.onReady();
    try {
      await initializeCameraController();
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.upload]);
  }

  @override
  void onClose() {
    super.onClose();
    cameraController?.dispose();
    cameraControllerDisposed.value = true;
    // if(!trimmer.isDisposed) trimmer.dispose();
  }

  Future<void> initializeCameraController() async {
    try {
      cameras = await availableCameras();
      final rearCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back);
      cameraController = CameraController(rearCamera, ResolutionPreset.high);
      await cameraController?.initialize();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }
  
  @override
  Future<void> handleImage({AppFileFrom appFileFrom = AppFileFrom.gallery,
    UploadImageType uploadImageType = UploadImageType.post, double ratioX = 1,
    double ratioY = 1, XFile? imageFile, BuildContext? context}) async {

    try {
      if(mediaFile.value.path.isNotEmpty) clearMedia();

      if(imageFile == null) {
        switch (appFileFrom) {
          case AppFileFrom.gallery:
            mediaFile.value = (await ImagePicker().pickImage(source: ImageSource.gallery,
                imageQuality: AppConstants.imageQuality)) ?? XFile('');
            update([AppPageIdConstants.upload, AppPageIdConstants.onBoardingAddImage, AppPageIdConstants.createBand]);
            break;
          case AppFileFrom.camera:
            if(cameraController != null) {
              takePhoto.value = true;
              ///VERIFY IF NEEDED
              // if(!cameraController!.value.isInitialized) await initializeCameraController();
              if(context != null) Navigator.pop(context);

              ///DEPRECATED
              // imageFile.value = (await ImagePicker().pickImage(
              //     source: ImageSource.camera,
              //     imageQuality: AppConstants.imageQuality,
              //   )
              // )!;

              ///THERE IS NO SOLUTION YET TO FRONTAL PHOTO MIRRORED - OCTOBER 2023
              // imageFile.value = await cameraController!.takePicture();
              // bool isFrontal = await isFrontCameraPhoto(File(imageFile.value.path));
              // if(isFrontal) {
              //   mirrorFrontCameraPhoto(File(imageFile.value.path));
              // }
              break;
            }
        }
      } else {
        mediaFile.value = imageFile;
      }

      if(mediaFile.value.path.isNotEmpty) {
        postType = PostType.image;
        mediaFile.value = await AppUtilities.compressImageFile(mediaFile.value);
        croppedImageFile.value = await AppUtilities.cropImage(mediaFile.value, ratioX: ratioX, ratioY: ratioY);
        if(croppedImageFile.value.path.isEmpty) {
          clearMedia();
          if(context != null) Navigator.pop(context);
          return;
        }

        switch(uploadImageType) {
          case UploadImageType.post:
            takePhoto.value = false;
            Get.toNamed(AppRouteConstants.postUploadDescription);
            break;
          case UploadImageType.thumbnail:
            // TODO: Handle this case.
            break;
          case UploadImageType.event:
            // TODO: Handle this case.
            break;
          case UploadImageType.profile:
            // TODO: Handle this case.
            break;
          case UploadImageType.cover:
            // TODO: Handle this case.
            break;
          case UploadImageType.comment:
            // TODO: Handle this case.
            break;
          case UploadImageType.message:
            // TODO: Handle this case.
            break;
          case UploadImageType.itemlist:
            // TODO: Handle this case.
            break;
          case UploadImageType.releaseItem:
            // TODO: Handle this case.
            break;
        }
      }
    }  catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.upload, AppPageIdConstants.onBoardingAddImage, AppPageIdConstants.createBand]);
  }

  @override
  Future<String> handleUploadImage(UploadImageType uploadImageType) async {
    logger.d("");
    String imageUrl = "";

    try {
      imageUrl = await AppUploadFirestore()
          .uploadImage(_mediaId, croppedImageFile.value.path.isNotEmpty
          ? croppedImageFile.value : File(mediaFile.value.path), uploadImageType);
      logger.d("File uploaded to $imageUrl");
    } catch (e) {
      logger.e(e.toString());
    }

    return imageUrl;
  }

  @override
  Future<void> handleVideo({AppFileFrom appFileFrom = AppFileFrom.gallery, XFile? videoFile, BuildContext? context}) async {

    try {

      if(mediaFile.value.path.isNotEmpty) clearMedia();

      if(videoFile == null) {
        switch (appFileFrom) {
          case AppFileFrom.gallery:
            mediaFile.value = (await ImagePicker().pickVideo(source: ImageSource.gallery))  ?? XFile('');
            break;
          case AppFileFrom.camera:
          // file = (await ImagePicker().pickVideo(source: ImageSource.camera))!;
          // break;
        }
      } else {
        mediaFile.value = videoFile;
      }

      if(mediaFile.value.path.isNotEmpty) {
        postType = PostType.video;

        Get.to(() => StatefulVideoEditor(file: File(mediaFile.value.path,)));

        ///DELETE IN NEXT CHECK UP
        // _thumbnailFile = await VideoCompress.getFileThumbnail(
        //   mediaFile.value.path,
        //   quality: AppConstants.videoQuality,
        // );
        // await initializeVideoTrimmer();
        //
        // ///DEPRECATED
        // // videoPlayerController = VideoPlayerController.file(videoFile);
        // // videoPlayerController = trimmer.videoPlayerController!;
        // // await videoPlayerController.initialize();
        // //
        // // if (videoPlayerController.value.duration.inSeconds > AppConstants.maxVideoDurationInSeconds) {
        // //   trimmedEndValue.value = AppConstants.maxVideoDurationInSeconds.toDouble();
        // //   // return;
        // // }
        // //
        // // videoPlayerController.setLooping(true);
        //
        // Get.toNamed(AppRouteConstants.postUploadDescription);
      }

    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.upload]);
  }

  Future<void> setProcessedVideo(XFile videoFile) async {

    try {

      if(mediaFile.value.path.isNotEmpty) clearMedia();
      mediaFile.value = videoFile;

      if(mediaFile.value.path.isNotEmpty) {
        postType = PostType.video;
        _thumbnailFile = await VideoCompress.getFileThumbnail(
          mediaFile.value.path,
          quality: AppConstants.videoQuality,
        );

        ///DELETE IN NEXT CHECK UP
        // await initializeVideoTrimmer();
        // videoPlayerController = trimmer.videoPlayerController!;
        videoPlayerController = VideoPlayerController.file(File(videoFile.path));

        await videoPlayerController.initialize();
        videoPlayerController.play();
        isPlaying.value = true;
        videoPlayerController.setLooping(true);

        ///DELETE IN NEXT CHECK UP
        // if (videoPlayerController.value.duration.inSeconds > AppConstants.maxVideoDurationInSeconds) {
        //   trimmedEndValue.value = AppConstants.maxVideoDurationInSeconds.toDouble();
        //   // return;
        // }
        //


        Get.toNamed(AppRouteConstants.postUploadDescription);
      }

    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.upload]);
  }



  Future<void> validateMediaSize() async {
    AppUtilities.logger.d("validateMediaSize");

    try {
      File videoFile = File(mediaFile.value.path);
      int fileSize = await videoFile.length();

      if(fileSize > AppConstants.maxVideoFileSize) {
        AppUtilities.logger.w("VideoFile size $fileSize is above maximum. Starting compression");
        MediaInfo? mediaInfo = await VideoCompress.compressVideo(mediaFile.value.path, quality: VideoQuality.LowQuality);
        if(mediaInfo != null) videoFile = mediaInfo.file!;
        fileSize = await videoFile.length();

        if(fileSize <= AppConstants.maxVideoFileSize) {
          AppUtilities.logger.w("VideoFile size $fileSize is now below limit");
          mediaFile.value = XFile(videoFile.path);
        } else {
          AppUtilities.logger.w("VideoFile size $fileSize is still above limit");
          Get.back();
          AppUtilities.showSnackBar(message: AppTranslationConstants.videoAboveSizeMsg);
          return;
        }
      } else {
        AppUtilities.logger.d("VideoFile size $fileSize is below maximum.");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.upload]);
  }

  @override
  Future<void> playPauseVideo() async {
    logger.d("playPauseVideo");
    videoPlayerController.value.isPlaying ? await videoPlayerController.pause() : videoPlayerController.play();
    logger.t("isPlaying ${videoPlayerController.value.isPlaying}");

    ///DELETE IN NEXT CHECK UP
    // bool playbackState = await trimmer.value.videoPlaybackControl(
    //   startValue: trimmedStartValue.value,
    //   endValue: trimmedEndValue.value,
    // );
    // isPlaying.value = playbackState;

    isPlaying.value = !isPlaying.value;
    logger.d("isPlaying: $isPlaying");
    update([AppPageIdConstants.upload]);
  }

  void setTrimmedStart(double value) {
    trimmedStartValue.value = value;
    update([AppPageIdConstants.upload]);
  }

  void setTrimmedEnd(double value) {
    trimmedEndValue.value = value;
    update([AppPageIdConstants.upload]);
  }

  void setIsPlaying(bool value) {
    if(isPlaying.value != value) {
      isPlaying.value = value;
      update([AppPageIdConstants.upload]);
    }
  }


  @override
  void clearMedia(){
    mediaFile.value =  XFile("");
    croppedImageFile.value = File("");
    trimmedMediaFile.value = File("");
    postType = PostType.pending;
    if(videoPlayerController.value.isInitialized) disposeVideoPlayer();
    // if(!trimmer.isDisposed) trimmer.dispose();
    update([AppPageIdConstants.upload, AppPageIdConstants.postComments,
      AppPageIdConstants.timeline, AppPageIdConstants.onBoardingAddImage, AppPageIdConstants.event]);
  }

  @override
  void disposeVideoPlayer() {
    if(videoPlayerController.value.isPlaying) videoPlayerController.pause();
    videoPlayerController = VideoPlayerController.networkUrl(Uri());
    videoPlayerController.dispose();
  }

  @override
  Future<void> handleSubmit() async {
    isUploading.value = true;
    isButtonDisabled.value = true;

    update([AppPageIdConstants.upload]);

    try {
      if (postType == PostType.image) {
        mediaUrl = await AppUploadFirestore().uploadImage(_mediaId, croppedImageFile.value, UploadImageType.post);
        logger.d("File uploaded to $mediaUrl");
      } else if (postType == PostType.video) {
        disposeVideoPlayer();
        // mediaFile.value = XFile(await saveVideo());
        await validateMediaSize();
        _file = File(mediaFile.value.path);
        thumbnailUrl = await AppUploadFirestore().uploadImage(_mediaId, _thumbnailFile, UploadImageType.thumbnail);
        mediaUrl = await AppUploadFirestore().uploadVideo(_mediaId, _file);
        logger.d("Video File uploaded to $mediaUrl & thumbnailURL to $thumbnailUrl");
      } else {
        postType = PostType.caption;
      }

      if(mediaUrl.isNotEmpty || postType == PostType.caption) {
        await handlePostUpload();
      } else {
        Get.offAllNamed(AppRouteConstants.home);
        AppUtilities.showSnackBar(message: AppTranslationConstants.postUploadErrorMsg.tr);
      }
    } catch (e) {
      logger.e(e.toString());
      Get.offAllNamed(AppRouteConstants.home);
      AppUtilities.showSnackBar(message: AppTranslationConstants.postUploadErrorMsg.tr);
    }
  }

  @override
  Future<void> handlePostUpload() async {
    logger.t("handlePostUpload");

    try {
      if (_position?.latitude == 0 && profile.position?.latitude != 0.0) {
        _position = profile.position!;
      }

      List<String> postHashtags = [];
      extractHashTags(captionController.text).forEach((element) {
        postHashtags.add(element.substring(1));
      });

      String location = locationController.text.isNotEmpty ? locationController.text
          :  locationSuggestions.value.isNotEmpty ? locationSuggestions.value.first : "";

      _post = Post(caption: captionController.text,
          hashtags: postHashtags,
          type: postType,
          profileName: profile.name,
          profileImgUrl: profile.photoUrl,
          ownerId: profile.id,
          thumbnailUrl: thumbnailUrl,
          mediaUrl: mediaUrl,
          position: _position,
          location:  location,
          isCommentEnabled: true,
          createdTime: DateTime.now().millisecondsSinceEpoch);
      _post.id = await PostFirestore().insert(_post);

      if(_post.hashtags.isNotEmpty) {
        for (var hashtagId in _post.hashtags) {
          Hashtag hashtag = Hashtag(id: hashtagId, postIds: [_post.id] , createdTime: DateTime.now().millisecondsSinceEpoch);
          if(await HashtagFirestore().exists(hashtagId)) {
            await HashtagFirestore().addPost(hashtagId, _post.id);
          } else {
            await HashtagFirestore().insert(hashtag);
          }
        }
      }

      if(_post.id.isNotEmpty) {
        locationController.clear();
        captionController.clear();
        isUploading.value = false;
        mediaFile.value =  XFile("");

        if(await ProfileFirestore().addPost(_post.ownerId, _post.id)) {
          profile.posts!.add(_post.id);
        }

        // await Get.find<TimelineController>().getTimeline();
        FirebaseMessagingCalls.sendGlobalPushNotification(
          fromProfile: profile,
          notificationType: PushNotificationType.post,
          referenceId: _post.id,
          imgUrl: _post.mediaUrl

        );

        await Get.find<TimelineController>().getTimeline();
        Get.offAllNamed(AppRouteConstants.home);
      }

    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void updatePage() {
    update([AppPageIdConstants.upload]);
  }

  @override
  void setUserLocation(String locationSuggestion) {
    locationController.text = locationSuggestion;
    update([AppPageIdConstants.upload]);
  }

  @override
  void clearUserLocation() {
    locationController.clear();
    update([AppPageIdConstants.upload]);
  }


  @override
  void getBackToUploadImage(BuildContext context) {
    clearMedia();
    Navigator.pop(context);
    update([AppPageIdConstants.upload]);
  }

  void setCaption(String text) {
    caption.value = text;
    update([AppPageIdConstants.upload]);
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
  //   imageFile.value = XFile(mirroredImgFile.path);
  // }

///DELETE IN NEXT CHECK UP
// Future<void> initializeVideoTrimmer() async {
//   AppUtilities.logger.d("initializeVideoTrimmer");
//
//   int maxDurationInSeconds = userController.user!.userRole == UserRole.subscriber
//       ? AppConstants.verifiedMaxVideoDurationInSeconds : AppConstants.adminMaxVideoDurationInSeconds;
//
//   try {
//     // await trimmer.value.loadVideo(videoFile: File(mediaFile.value.path));
//     // await trimmer.value.videoPlayerController?.initialize();
//     // await trimmer.value.videoPlayerController?.setLooping(true);
//     // if (trimmer.value.videoPlayerController!.value.duration.inSeconds <= maxDurationInSeconds) {
//     //   trimmedEndValue.value = maxDurationInSeconds.toDouble();
//     // } else {
//     //   trimmedEndValue.value = trimmer.value.videoPlayerController!.value.duration.inSeconds.toDouble();
//     // }
//     // videoPlayerController = trimmer.videoPlayerController!;
//     // await videoPlayerController.initialize();
//     //
//
//     //
//   } catch (e) {
//     AppUtilities.logger.e(e.toString());
//   }
//
//   update([AppPageIdConstants.upload]);
// }

// Future<String> saveVideo() async {
//   String trimmedVideoPath = '';
//
//   try {
//     // await trimmer.value.saveTrimmedVideo(
//     //     startValue: trimmedStartValue.value,
//     //     endValue: trimmedEndValue.value,
//     //     onSave: (value) {
//     //       AppUtilities.logger.i('Trimming Video to output path: $value');
//     //       trimmedVideoPath = value.toString();
//     //       AppUtilities.showSnackBar(message: 'Video Saved with new duration of ${AppUtilities.getDurationInMinutes(trimmedEndValue.value.ceil() - trimmedStartValue.value.ceil())} successfully');
//     //     });
//   } catch (e) {
//     AppUtilities.logger.e(e.toString());
//   }
//
//   return trimmedVideoPath;
// }


}
