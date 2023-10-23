import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:neom_commons/core/utils/enums/app_file_from.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';

abstract class PostUploadService {

  Future<void> handleImage({AppFileFrom appFileFrom = AppFileFrom.gallery,
    UploadImageType uploadImageType = UploadImageType.post, double ratioX = 1,
    double ratioY = 1, XFile? imageFile, BuildContext? context});
  Future<String> handleUploadImage(UploadImageType uploadImageType);
  void clearMedia();

  Future<void> handleVideo({AppFileFrom appFileFrom = AppFileFrom.gallery, XFile? videoFile, BuildContext? context});
  // Future<void> playPauseVideo();
  void disposeVideoPlayer();


  Future<void> handleSubmit();
  Future<void> handlePostUpload();

  void setUserLocation(String locationSuggestion);
  void clearUserLocation();
  void getBackToUploadImage(BuildContext context);
  void updatePage();

}
