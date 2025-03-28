import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
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
import 'package:neom_commons/core/data/implementations/maps_controller.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/hashtag.dart';
import 'package:neom_commons/core/domain/model/place.dart';
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
import 'package:neom_maps_services/places.dart';

import '../../../camera/neom_camera_controller.dart';
import '../../domain/use_cases/post_upload_service.dart';
import 'create_clips/stateful_video_editor.dart';

class PostUploadController extends GetxController implements PostUploadService {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();
  final mapsController = Get.put(MapsController());

  AppProfile profile = AppProfile();
  Post _post = Post();
  Position? _position;

  final RxBool isButtonDisabled = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool isUploading = false.obs;
  final RxBool cropImage = true.obs;
  final Rx<XFile> mediaFile = XFile("").obs;
  final Rx<File> croppedImageFile = File("").obs;
  final Rx<File> trimmedMediaFile = File("").obs;
  final RxList<String> locationSuggestions = <String>[].obs;
  final RxString caption = "".obs;
  final RxBool takePhoto = false.obs;

  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  VideoPlayerController? videoPlayerController;

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
  final RxBool maxVideosPerWeekReached = false.obs;
  double aspectRatio = 1;

  UploadImageType uploadImageType = UploadImageType.post;

  @override
  void onInit() {
    super.onInit();
    logger.t("PostUpload Controller Init");
    profile = userController.profile;

    try {

    } catch (e) {
      logger.e(e.toString());
    }

    // clearMedia();
  }

  @override
  void onReady() {
    super.onReady();

    try {
      verifyVideosPerWeekLimit();
      if(profile.position != null) getLocationSuggestions();
      isLoading.value = false;
    } catch (e) {
      logger.e(e.toString());
    }

    // update([AppPageIdConstants.upload]);
  }

  Future<void> verifyVideosPerWeekLimit() async {
    List<Post> profilePosts = await PostFirestore().getProfilePosts(profile.id);
    DateTime today = DateTime.now();
    DateTime previousMonday = today.subtract(Duration(days: (today.weekday - 1 + 7) % 7));
    int videosPerWeekCounter = 0;
    
    for (var profilePost in profilePosts) {
      if(profilePost.type == PostType.video && profilePost.createdTime > previousMonday.millisecondsSinceEpoch) {
        videosPerWeekCounter++;
      }
    }
    
    if(videosPerWeekCounter >= AppConstants.maxVideosPerWeek) maxVideosPerWeekReached.value = true;
  }

  @override
  void onClose() {
    super.onClose();
    // if(!trimmer.isDisposed) trimmer.dispose();
  }

  Future<void> getLocationSuggestions() async {
    locationSuggestions.value = await GeoLocatorController().getNearbySimpleAddresses(profile.position!);

    // locationSuggestions.value.add(profileLocation);
    _position = await GeoLocatorController().getCurrentPosition();

    if(_position != null) {
      String currentPosition = await GeoLocatorController().getAddressSimple(_position!);
      if(!locationSuggestions.value.contains(currentPosition)) {
        locationSuggestions.value.add(currentPosition);
      }
    }
  }

  Future<void> handleMedia(XFile file) async {
    if (file.path.isEmpty) {
      AppUtilities.logger.d('No se seleccionó ningún archivo.');
      return;
    }

    // Obtener la extensión del archivo para determinar si es imagen o video
    String fileExtension = file.path.split('.').last.toLowerCase();
    List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    List<String> videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv'];

    if (imageExtensions.contains(fileExtension)) {
      AppUtilities.logger.d('Archivo seleccionado es una imagen: ${file.path}');
      await handleImage(imageFile: file);
    } else if (videoExtensions.contains(fileExtension)) {
      AppUtilities.logger.d('Archivo seleccionado es un video: ${file.path}');
      await handleVideo(videoFile: file);
    } else {
      AppUtilities.logger.w('Formato de archivo no soportado: ${file.path}');
    }
  }

  @override
  Future<void> handleImage({AppFileFrom appFileFrom = AppFileFrom.gallery,
    UploadImageType imageType = UploadImageType.post, XFile? imageFile,
    double ratioX = 1, double ratioY = 1, bool crop = true, BuildContext? context}) async {

    try {
      if(mediaFile.value.path.isNotEmpty) clearMedia();
      cropImage.value = crop;
      uploadImageType = imageType;

      if(imageFile == null) {
        switch (appFileFrom) {
          case AppFileFrom.gallery:
            mediaFile.value = (await ImagePicker().pickImage(source: ImageSource.gallery)) ?? XFile('');
          update([AppPageIdConstants.upload, AppPageIdConstants.onBoardingAddImage, AppPageIdConstants.createBand]);
          //   pickMediaFromDevice();

            break;
          case AppFileFrom.camera:
            NeomCameraController neomCameraController = Get.put(NeomCameraController());
            if(neomCameraController.controller?.value.isInitialized ?? false) {
              takePhoto.value = true;
              if(context != null) Navigator.pop(context);

              ///THERE IS NO SOLUTION YET TO FRONTAL PHOTO MIRRORED - OCTOBER 2023
              // imageFile.value = await cameraController!.takePicture();
              // bool isFrontal = await isFrontCameraPhoto(File(imageFile.value.path));
              // if(isFrontal) {
              //   mirrorFrontCameraPhoto(File(imageFile.value.path));
              // }
              break;
            } else {
              await neomCameraController.initializeCameraController();
              takePhoto.value = true;
              if(context != null) Navigator.pop(context);
            }
        }
      } else {
        mediaFile.value = imageFile;
      }


      if(mediaFile.value.path.isNotEmpty) {
        postType = PostType.image;
        mediaFile.value = await AppUtilities.compressImageFile(mediaFile.value);

        if(cropImage.value) {
          croppedImageFile.value = await AppUtilities.cropImage(mediaFile.value, ratioX: ratioX, ratioY: ratioY);
          if(croppedImageFile.value.path.isEmpty) {
            clearMedia();
            if(context != null) Navigator.pop(context);
            return;
          }
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
    logger.d("handleUploadImage ${uploadImageType.name}");
    String imageUrl = "";

    try {
      imageUrl = await AppUploadFirestore().uploadImage(_mediaId,
          croppedImageFile.value.path.isNotEmpty
              ? croppedImageFile.value : File(mediaFile.value.path), uploadImageType);
      logger.d("File uploaded to $imageUrl");
    } catch (e) {
      logger.e(e.toString());
    }

    return imageUrl;
  }

  @override
  Future<void> handleVideo({AppFileFrom appFileFrom = AppFileFrom.gallery, XFile? videoFile, BuildContext? context}) async {
    AppUtilities.logger.d("handleVideo");

    try {

      if(maxVideosPerWeekReached.value) {
        AppUtilities.showSnackBar(message: AppTranslationConstants.maxVideosPerWeekReachedMsg.tr, duration: const Duration(seconds: 5));
        return;
      }

      if(mediaFile.value.path.isNotEmpty) clearMedia();

      if(videoFile == null) {
        switch (appFileFrom) {
          case AppFileFrom.gallery:
            mediaFile.value = (await ImagePicker().pickVideo(source: ImageSource.gallery))  ?? XFile('');
            break;
          case AppFileFrom.camera:
            ///NOT NEEDED YET
            /// file = (await ImagePicker().pickVideo(source: ImageSource.camera))!;
            /// break;
        }
      } else {
        mediaFile.value = videoFile;
      }

      if(mediaFile.value.path.isNotEmpty) {
        postType = PostType.video;
        Get.to(() => StatefulVideoEditor(file: File(mediaFile.value.path,)));
      }
    } catch (e) {
      logger.e(e.toString());
    }

    // update([AppPageIdConstants.upload]);
  }


  Future<void> setProcessedVideo(XFile videoFile) async {
    AppUtilities.logger.d("setProcessedVideo");
    try {

      if(mediaFile.value.path.isNotEmpty) clearMedia();
      mediaFile.value = videoFile;

      if(mediaFile.value.path.isNotEmpty) {
        postType = PostType.video;
        // _thumbnailFile = await VideoCompress.getFileThumbnail(
        //   mediaFile.value.path,
        //   quality: AppConstants.videoQuality,
        // );

        await initializeVideoPlayerController(File(videoFile.path));
        videoPlayerController?.play();
        isPlaying.value = true;
        videoPlayerController?.setLooping(true);

        Get.toNamed(AppRouteConstants.postUploadDescription);
      }

    } catch (e) {
      logger.e(e.toString());
    }

    // update([AppPageIdConstants.upload]);
  }

  Future<void> initializeVideoPlayerController(File file) async {
    AppUtilities.logger.d("initializeVideoPlayerController");

    videoPlayerController = VideoPlayerController.file(file);
    await videoPlayerController?.initialize();

    if(videoPlayerController?.value.isInitialized ?? false) {
      final videoSize = videoPlayerController!.value.size;
      aspectRatio = videoSize.width / videoSize.height;
    }
  }


  Future<void> validateMediaSize() async {
    AppUtilities.logger.t("validateMediaSize");

    try {
      File videoFile = File(mediaFile.value.path);
      int fileSize = await videoFile.length();

      if(fileSize > AppConstants.maxVideoFileSize) {
        AppUtilities.logger.w("VideoFile size $fileSize is above maximum. Starting compression");
        MediaInfo? mediaInfo = await VideoCompress.compressVideo(mediaFile.value.path, quality: VideoQuality.DefaultQuality);
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
    (videoPlayerController?.value.isPlaying ?? false) ? await videoPlayerController?.pause() : videoPlayerController?.play();
    logger.t("isPlaying ${videoPlayerController?.value.isPlaying}");

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
    if(videoPlayerController?.value.isInitialized ?? false) disposeVideoPlayer();
    // if(!trimmer.isDisposed) trimmer.dispose();
    update([AppPageIdConstants.upload, AppPageIdConstants.postComments,
      AppPageIdConstants.timeline, AppPageIdConstants.onBoardingAddImage, AppPageIdConstants.event]);
  }

  @override
  void disposeVideoPlayer() {
    if(videoPlayerController?.value.isPlaying ?? false) videoPlayerController?.pause();
    videoPlayerController = VideoPlayerController.networkUrl(Uri());
    videoPlayerController?.dispose();
  }

  @override
  Future<void> handleSubmit() async {
    isUploading.value = true;
    isButtonDisabled.value = true;

    // update([AppPageIdConstants.upload]);

    try {
      if (postType == PostType.image) {
        mediaUrl = await AppUploadFirestore().uploadImage(_mediaId,  croppedImageFile.value.path.isNotEmpty
            ? croppedImageFile.value : File(mediaFile.value.path), UploadImageType.post);
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
        createdTime: DateTime.now().millisecondsSinceEpoch,
        verificationLevel: profile.verificationLevel,
        lastInteraction: DateTime.now().millisecondsSinceEpoch,
        aspectRatio: aspectRatio,
      );

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

        if (Get.isRegistered<TimelineController>()) {
          await Get.find<TimelineController>().getTimeline();
        } else {
          await Get.put(TimelineController()).getTimeline();
        }

        locationController.clear();
        captionController.clear();
        isUploading.value = false;
        mediaFile.value =  XFile("");
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

  Future<void> pickMediaFromDevice() async {
    // Abre el selector permitiendo escoger archivos multimedia (imágenes y videos)
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        // Asigna el archivo seleccionado a mediaFile
        mediaFile.value = XFile(file.path!);

        // Determina si el archivo es imagen o video según su extensión
        String ext = file.extension?.toLowerCase() ?? "";
        if (['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv'].contains(ext)) {
          postType = PostType.video;
          // Por ejemplo, navega al editor de video
          Get.to(() => StatefulVideoEditor(file: File(file.path!)));
        } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
          postType = PostType.image;
          // Aquí podrías comprimir o recortar la imagen según corresponda
          mediaFile.value = await AppUtilities.compressImageFile(mediaFile.value);
          // Por ejemplo, navega a la pantalla de descripción de post
          Get.toNamed(AppRouteConstants.postUploadDescription);
        } else {
          AppUtilities.logger.w("Tipo de archivo no soportado: $ext");
        }
        update([
          AppPageIdConstants.upload,
          AppPageIdConstants.onBoardingAddImage,
          AppPageIdConstants.createBand,
        ]);
      }
    }
  }

  Future<void> setTakePhoto({bool take = true}) async {
    NeomCameraController neomCameraController = Get.put(NeomCameraController());
    await neomCameraController.initializeCameraController();
    takePhoto.value = take;
  }

  @override
  Future<void> getLocation(context) async {
    AppUtilities.logger.d("getEventPlace for: ${locationController.text}");

    try {
      Prediction prediction = await mapsController.placeAutoComplete(context, locationController.text);
      Place place = await mapsController.predictionToGooglePlace(prediction);
      locationController.text = place.name;
      FocusScope.of(context).requestFocus(FocusNode()); //remove focus
    } catch (e) {
      AppUtilities.logger.d(e.toString());
    }

    update([AppPageIdConstants.upload]);
  }

}
