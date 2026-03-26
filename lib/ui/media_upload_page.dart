import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import '../utils/constants/media_upload_translation_constants.dart';
import 'media_upload_controller.dart';
import 'media_upload_web_controller.dart';
import 'widgets/media_upload_grid.dart';
import 'widgets/media_upload_web_picker.dart';

class MediaUploadPage extends StatelessWidget {
  const MediaUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWeb(context);
    return _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return SintBuilder<MediaUploadController>(
      id: AppPageIdConstants.upload,
      init: MediaUploadController(),
      builder: (controller) => Scaffold(
        appBar: SintAppBar(
          leading: IconButton(icon: const Icon(Icons.close),
            onPressed: () => Sint.back(),
          ),
          title: MediaUploadTranslationConstants.mediaUpload.tr, centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () async => await Sint.toNamed(AppRouteConstants.camera),
            ),
          ],
        ),
        backgroundColor: AppFlavour.getBackgroundColor(),
        body: Obx(()=> controller.isLoading.value ? AppCircularProgressIndicator()
            : Container(
            decoration: AppTheme.appBoxDecoration,
            child: MediaUploadGrid(mediaUploadController: controller)
        ),),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return SintBuilder<MediaUploadWebController>(
      id: AppPageIdConstants.upload,
      init: MediaUploadWebController(),
      builder: (controller) => Scaffold(
        appBar: SintAppBar(
          leading: IconButton(icon: const Icon(Icons.close),
            onPressed: () => Sint.back(),
          ),
          title: MediaUploadTranslationConstants.mediaUpload.tr,
          centerTitle: true,
        ),
        backgroundColor: AppFlavour.getBackgroundColor(),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: MediaUploadWebPicker(controller: controller),
        ),
      ),
    );
  }

}
