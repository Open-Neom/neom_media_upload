import 'dart:io';

import 'package:neom_commons/core/utils/enums/upload_image_type.dart';


abstract class UploadRepository {

  Future<String> uploadImage(String mediaId, File file, UploadImageType uploadImageType);
  Future<String> uploadVideo(String mediaId, File file);

}
