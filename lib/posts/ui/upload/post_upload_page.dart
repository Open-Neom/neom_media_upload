import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/core/utils/constants/app_route_constants.dart';

import '../widgets/post_media_grid.dart';
import 'post_upload_controller.dart';

class PostUploadPage extends StatelessWidget {
  const PostUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostUploadController>(
        id: AppPageIdConstants.upload,
        init: PostUploadController(),
    builder: (_) => Scaffold(
      // extendBodyBehindAppBar: true,
      appBar: AppBarChild(
        leadingWidget: IconButton(icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppTranslationConstants.newPost.tr, centerTitle: true,
        actionWidgets: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => Get.toNamed(AppRouteConstants.camera),
          ),
        ],
        color: AppColor.getMain(),
      ),
      backgroundColor: AppColor.main50,
      body: Obx(()=>_.isLoading.value ? AppCircularProgressIndicator():Container(
          decoration: AppTheme.appBoxDecoration,
          child: PostMediaGrid(postUploadController: _)
      ),),
    ),);
  }

}
