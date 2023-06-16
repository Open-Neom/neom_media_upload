import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hashtagable/functions.dart';
import 'package:image_cropper/image_cropper.dart';
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
import 'package:neom_commons/core/utils/app_color.dart';
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

class PostUploadController extends GetxController implements PostUploadService {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();
  final _mediaId = const Uuid().v4();

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isUploading = false.obs;
  bool get isUploading => _isUploading.value;
  set isUploading(bool isUploading) => _isUploading.value = isUploading;

  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();

  VideoPlayerController videoPlayerController = VideoPlayerController.network("");

  final Rx<XFile> _imageFile = XFile("").obs;
  XFile get imageFile => _imageFile.value;
  set imageFile(XFile imageFile) => _imageFile.value = imageFile;

  final Rx<File> _croppedImageFile = File("").obs;
  File get croppedImageFile => _croppedImageFile.value;
  set croppedImageFile(File croppedImage) => _croppedImageFile.value = croppedImage;

  File _file = File("");
  AppProfile profile = AppProfile();
  Post _post = Post();

  String _mediaUrl = "";
  String get mediaUrl => _mediaUrl;
  String thumbnailUrl = "";

  Position? _position;
  File _thumbnailFile = File("");
  File get thumbnailFile => _thumbnailFile;

  final RxList<String> _locationSuggestions = <String>[].obs;
  List<String> get locationSuggestions => _locationSuggestions;
  set locationSuggestions(List<String> locationSuggestions) => _locationSuggestions.value = locationSuggestions;

  PostType postType = PostType.pending;

  final RxString _caption = "".obs;
  String get caption => _caption.value;
  set caption(String caption) => _caption.value = caption;

  @override
  void onInit() async {
    super.onInit();
    logger.d("PostUpload Controller Init");
    profile = userController.profile;

    try {
      if(profile.position != null) {
        String profileLocation = await GeoLocatorController().getAddressSimple(profile.position!);
        locationSuggestions.add(profileLocation);
        _position = await GeoLocatorController().getCurrentPosition();

        if(_position != null) {
          String currentPosition = await GeoLocatorController().getAddressSimple(_position!);
          if(!locationSuggestions.contains(currentPosition)) {
            locationSuggestions.add(currentPosition);
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    clearImage();
  }


  @override
  Future<void> handleImage({AppFileFrom appFileFrom = AppFileFrom.gallery,
    UploadImageType uploadImageType = UploadImageType.post, double ratioX = 1, double ratioY = 1}) async {

    try {
      if(imageFile.path.isNotEmpty) clearImage();

      final imagePicker = ImagePicker();

      switch (appFileFrom) {
        case AppFileFrom.camera:
          imageFile = (await imagePicker.pickImage(
              source: ImageSource.camera,
              imageQuality: AppConstants.imageQuality)
          )!;
          break;
        case AppFileFrom.gallery:
          imageFile = (await imagePicker.pickImage(
              source: ImageSource.gallery,
              imageQuality: AppConstants.imageQuality)
          )!;
          break;
      }

      postType = PostType.image;

      if(imageFile.path.isNotEmpty) {
        await compressFileImage();
        await cropImage(ratioX: ratioX, ratioY: ratioY);
        if(croppedImageFile.path.isEmpty) clearImage();
        postType = PostType.image;

        switch(uploadImageType) {
          case UploadImageType.post:
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

    update([AppPageIdConstants.upload,
      AppPageIdConstants.onBoardingAddImage,
      AppPageIdConstants.createBand]);
  }

  @override
  Future<void> compressFileImage() async {

    final lastIndex = imageFile.path.lastIndexOf(RegExp(r'.jp'));

    if(lastIndex >= 0) {
      String subPath = imageFile.path.substring(0, (lastIndex));
      String outPath = "${subPath}_out${imageFile.path.substring(lastIndex)}";
      imageFile = await FlutterImageCompress.compressAndGetFile(imageFile.path, outPath) ?? XFile("");
    }

  }


  @override
  Future<void> cropImage({double ratioX = 1, double ratioY = 1}) async {
    logger.d("Initializing Image Cropper");
    try {

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: CropAspectRatio(
            ratioX: ratioX,
            ratioY: ratioY
        ),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: AppTranslationConstants.adjustImage.tr,
            backgroundColor: Colors.black38,
            toolbarColor: AppColor.getMain(),
            toolbarWidgetColor: AppColor.white,
            statusBarColor: AppColor.getMain(),
            dimmedLayerColor: AppColor.main50,
            activeControlsWidgetColor: AppColor.getMain(),
            initAspectRatio: CropAspectRatioPreset.square
          ),
          IOSUiSettings(
            title: AppTranslationConstants.adjustImage.tr,
            cancelButtonTitle: AppTranslationConstants.cancel.tr,
            doneButtonTitle: AppTranslationConstants.done.tr,
            minimumAspectRatio: 1.0,
            showCancelConfirmationDialog: true,
            aspectRatioLockEnabled: true,
          )
        ],
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
      );

      croppedImageFile  = File(croppedFile?.path ?? "");


    } catch (e) {
      logger.e(e.toString());
    }
    logger.d("Cropped Image in file ${croppedImageFile.path}");

  }




  @override
  Future<String> handleUploadImage(UploadImageType uploadImageType) async {
    logger.d("");
    String imageUrl = "";

    try {
      imageUrl = await AppUploadFirestore()
          .uploadImage(_mediaId,
          croppedImageFile.path.isNotEmpty ? croppedImageFile : File(imageFile.path),
          uploadImageType);
      logger.d("File uploaded to $_mediaUrl");
    } catch (e) {
      logger.e(e.toString());
    }

    return imageUrl;
  }


  @override
  void clearImage(){
    imageFile =  XFile("");
    croppedImageFile = File("");
    postType = PostType.pending;
    if(videoPlayerController.value.isInitialized) disposeVideoPlayer();
    update([AppPageIdConstants.upload, AppPageIdConstants.postComments,
      AppPageIdConstants.timeline, AppPageIdConstants.onBoardingAddImage, AppPageIdConstants.event]);
  }


  @override
  Future<void> handleVideo(AppFileFrom appFileFrom) async {
    XFile file;

    try {
      switch (appFileFrom) {
        case AppFileFrom.camera:
          file = (await ImagePicker().pickVideo(source: ImageSource.camera))!;
          break;
        case AppFileFrom.gallery:
          file = (await ImagePicker().pickVideo(source: ImageSource.gallery))!;
          break;
      }

      Get.back();

      if(imageFile.path.isNotEmpty) clearImage();

      imageFile = file;
      postType = PostType.video;

      File videoFile = File(imageFile.path);
      videoPlayerController = VideoPlayerController.file(videoFile);
      videoPlayerController.initialize();
      videoPlayerController.setLooping(true);

      _thumbnailFile = await VideoCompress.getFileThumbnail(
          imageFile.path,
          quality: AppConstants.videoQuality,
          position: -1 // default(-1)
      );
    } catch (e) {
      logger.e(e.toString());
    }

    if(imageFile.path.isNotEmpty) Get.toNamed(AppRouteConstants.postUploadDescription);
    update([AppPageIdConstants.upload]);
  }


  @override
  Future<void> playPauseVideo() async {
    logger.d("");
    videoPlayerController.value.isPlaying ?
    await videoPlayerController.pause()
        : videoPlayerController.play();
    update([AppPageIdConstants.upload]);
  }


  @override
  void disposeVideoPlayer() {
    if(videoPlayerController.value.isPlaying) videoPlayerController.pause();
    videoPlayerController = VideoPlayerController.network("");
    videoPlayerController.dispose();
  }


  @override
  Future<void> handleSubmit() async {
    isUploading = true;
    isButtonDisabled = true;

    update([AppPageIdConstants.upload]);

    try {
      if (postType == PostType.image) {
        _mediaUrl = await AppUploadFirestore().uploadImage(_mediaId, croppedImageFile, UploadImageType.post);
      } else if (postType == PostType.video) {
        disposeVideoPlayer();
        _file = File(imageFile.path);
        thumbnailUrl = await AppUploadFirestore().uploadImage(_mediaId, _thumbnailFile, UploadImageType.thumbnail);
        _mediaUrl = await AppUploadFirestore().uploadVideo(_mediaId, _file);
      } else {
        postType = PostType.caption;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("File uploaded to $_mediaUrl");
    await handlePostUpload();
  }


  @override
  Future<void> handlePostUpload() async {
    logger.d("");

    try {
      if (_position?.latitude == 0 && profile.position?.latitude != 0.0) {
        _position = profile.position!;
      }

      List<String> postHashtags = [];
      extractHashTags(captionController.text).forEach((element) {
        postHashtags.add(element.substring(1));
      });


      String location = locationController.text.isNotEmpty ? locationController.text
          :  locationSuggestions.isNotEmpty ? locationSuggestions.first : "";

      _post = Post(caption: captionController.text,
          hashtags: postHashtags,
          type: postType,
          profileName: profile.name,
          profileImgUrl: profile.photoUrl,
          ownerId: profile.id,
          thumbnailUrl: thumbnailUrl,
          mediaUrl: _mediaUrl,
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
        isUploading = false;
        imageFile =  XFile("");

        if(await ProfileFirestore().addPost(_post.ownerId, _post.id)) {
          profile.posts!.add(_post.id);
        }

        await Get.find<TimelineController>().getTimeline();

        FirebaseMessagingCalls.sendGlobalPushNotification(
          fromProfile: profile,
          notificationType: PushNotificationType.post,
          referenceId: _post.id,
          imgUrl: _post.mediaUrl
        );
      }

    } catch (e) {
      logger.e(e.toString());
    }


    Get.offAllNamed(AppRouteConstants.home);
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
  void getBackToUploadImage() {
    clearImage();
    Get.back();
    update([AppPageIdConstants.upload]);
  }

  void setCaption(String text) {
    caption = text;
    update([AppPageIdConstants.upload]);
  }

}
