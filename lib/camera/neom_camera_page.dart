
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/neom_commons.dart';

import 'neom_camera_controller.dart';

class NeomCameraPage extends StatelessWidget {

  const NeomCameraPage({super.key});


  @override
  Widget build(BuildContext context) {

    return GetBuilder<NeomCameraController>(
      id: AppPageIdConstants.camera,
      init: NeomCameraController(),
      builder: (_) => Scaffold(
      appBar: AppBarChild(
        leadingWidget: IconButton(icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppTranslationConstants.newPost.tr, centerTitle: true,
      ),
      backgroundColor: AppColor.main50,
      body: SizedBox(
        // height: AppTheme.fullHeight(context),
        child: Obx(()=> _.isLoading.value ? AppCircularProgressIndicator():Stack(
        alignment: Alignment.center,
        children: [
          (!_.isDisposed) ? SizedBox(
            width: AppTheme.fullWidth(context),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(50.0),
                bottomRight: Radius.circular(50.0),
              ),
              child: _.cameraPreviewWidget(),),
          ) : const CircularProgressIndicator(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: _.modeControlRowWidget(),
            )
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: GestureDetector(
                onTap: () {
                  if(_.controller != null && _.controller!.value.isInitialized && !_.controller!.value.isRecordingVideo) {
                    _.onTakePictureButtonPressed();
                  }
                },
                onLongPress: () {
                  if((_.uploadController.userController.user.isVerified) && _.controller != null
                      && _.controller!.value.isInitialized && !_.controller!.value.isRecordingVideo) {
                    _.onVideoRecordButtonPressed();
                  }
                },
                onLongPressEnd: (details) {
                  if((_.uploadController.userController.user.isVerified) && _.controller != null
                      && _.controller!.value.isInitialized && _.controller!.value.isRecordingVideo) {
                    _.onStopButtonPressed();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _.isRecording.value ? 90 : 80,
                  height: _.isRecording.value ? 90 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _.isRecording.value ? AppColor.red : AppColor.lightGrey,
                  ),
                  child: _.isRecording.value ? const Icon(Icons.stop, color: Colors.white, size: 45,) : null,
                ),
              ),
            ),
          ),
         ],),
        ),
      ),),
    );
  }

}
