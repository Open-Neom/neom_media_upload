import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';

class UploadUtilities {

  static Future<File> cropImage(XFile mediaFile, {double ratioX = 1, double ratioY = 1}) async {
    AppUtilities.logger.d("Initializing Image Cropper");

    File croppedImageFile = File("");
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: mediaFile.path,
        aspectRatio: CropAspectRatio(
            ratioX: ratioX,
            ratioY: ratioY
        ),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: AppTranslationConstants.adjustImage.tr,
            backgroundColor: AppColor.getMain(),
            toolbarColor: AppColor.getMain(),
            toolbarWidgetColor: AppColor.white,
            statusBarColor: AppColor.getMain(),
            dimmedLayerColor: AppColor.main50,
            activeControlsWidgetColor: AppColor.yellow,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
            // initAspectRatio: CropAspectRatioPreset.square,

          ),
          IOSUiSettings(
            title: AppTranslationConstants.adjustImage.tr,
            cancelButtonTitle: AppTranslationConstants.cancel.tr,
            doneButtonTitle: AppTranslationConstants.done.tr,
            minimumAspectRatio: 1.0,
            showCancelConfirmationDialog: true,
            aspectRatioLockEnabled: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          )
        ],
      );

      croppedImageFile = File(croppedFile?.path ?? "");


    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    AppUtilities.logger.d("Cropped Image in file ${croppedImageFile.path}");

    return croppedImageFile;
  }

  static Future<XFile> compressImageFile(XFile imageFile) async {

    XFile compressedImageFile = XFile('');
    CompressFormat compressFormat = CompressFormat.jpeg;

    try {
      ///DEPRECATED final lastIndex = imageFile.path.lastIndexOf(RegExp(r'.jp'));
      final lastIndex = imageFile.path.lastIndexOf(RegExp(r'\.jp|\.png'));


      if(lastIndex >= 0) {
        String subPath = imageFile.path.substring(0, (lastIndex));
        String fileFormat = imageFile.path.substring(lastIndex);

        if(fileFormat.contains(CompressFormat.png.name)){
          compressFormat = CompressFormat.png;
        }

        String outPath = "${subPath}_out$fileFormat";
        XFile? result = await FlutterImageCompress.compressAndGetFile(imageFile.path, outPath, format: compressFormat);

        if(result != null) {
          compressedImageFile = result;
          AppUtilities.logger.d("Image compressed successfully");
        } else {
          compressedImageFile = imageFile;
          AppUtilities.logger.w("Image was not compressed and return as before");
        }
      }
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }


    return compressedImageFile;
  }

}
