import 'dart:async';

import 'package:neom_commons/core/utils/enums/app_file_from.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';

abstract class PostUploadService {

  Future<void> handleImage(AppFileFrom appFileFrom);
  Future<void> handleEventImage();
  Future<void> compressFileImage();
  Future<void> cropImage();
  Future<String> handleUploadImage(UploadImageType uploadImageType);
  void clearImage();

  Future<void> handleVideo(AppFileFrom appFileFrom);
  Future<void> playPauseVideo();
  void disposeVideoPlayer();


  Future<void> handleSubmit();
  Future<void> handlePostUpload();

  void setUserLocation(String locationSuggestion);
  void clearUserLocation();
  void getBackToUploadImage();
  void updatePage();

}
