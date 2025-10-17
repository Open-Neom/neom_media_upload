import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import '../utils/constants/media_upload_translation_constants.dart';
import 'media_upload_controller.dart';
import 'widgets/media_upload_grid.dart';

class MediaUploadPage extends StatelessWidget {
  const MediaUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MediaUploadController>(
      id: AppPageIdConstants.upload,
      init: MediaUploadController(),
      builder: (controller) => Scaffold(
      appBar: AppBarChild(
        leadingWidget: IconButton(icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: MediaUploadTranslationConstants.mediaUpload.tr, centerTitle: true,
        actionWidgets: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => Get.toNamed(AppRouteConstants.camera),
          ),
        ],
        color: AppColor.getMain(),
      ),
      backgroundColor: AppFlavour.getBackgroundColor(),
      body: Obx(()=> controller.isLoading.value ? AppCircularProgressIndicator()
          : Container(
          decoration: AppTheme.appBoxDecoration,
          child: MediaUploadGrid(mediaUploadController: controller)
      ),),
    ),);
  }

}
