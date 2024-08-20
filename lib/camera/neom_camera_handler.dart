import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:video_player/video_player.dart';

import '../neom_posts.dart';

class NeomCameraHandler extends StatefulWidget {

  final CameraController? cameraController;

  ///CamerasDesceription still experimental to verify if needed to change from back to frontal
  final List<CameraDescription>? cameras;

  const NeomCameraHandler({this.cameraController, this.cameras, super.key});

  @override
  State<NeomCameraHandler> createState() {
    return _NeomCameraHandlerState();
  }
}

class _NeomCameraHandlerState extends State<NeomCameraHandler>
    with WidgetsBindingObserver, TickerProviderStateMixin {

  CameraController? controller;
  XFile? imageFile;
  XFile? videoFile;
  VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;

  bool enableAudio = true;
  int flashModeIndex = 0;
  Icon flashIcon = const Icon(Icons.flash_off);
  bool isRecording = false;
  bool isDisposed = false;

  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;
  List<CameraDescription> cameras = [];

  late PostUploadController uploadController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    controller = widget.cameraController;

    if (controller == null && !controller!.value.isInitialized) {
      _initializeCameraController(controller!.description);
    }

    onSetFlashModeButtonPressed(FlashMode.off);

    if (Get.isRegistered<PostUploadController>()) {
      uploadController = Get.find<PostUploadController>();
    } else {
      uploadController = PostUploadController();
      Get.put(uploadController);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // #docregion AppLifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      setState(() {
        isDisposed = true;
      });
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }
  // #enddocregion AppLifecycle

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTheme.fullHeight(context),
      child: Stack(
      alignment: Alignment.center,
      children: [
        (!isDisposed) ? SizedBox(
          width: AppTheme.fullWidth(context),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(50.0),
              bottomRight: Radius.circular(50.0),
            ),
            child: _cameraPreviewWidget(),),
        ) : const CircularProgressIndicator(),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: _modeControlRowWidget(),
          )
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: GestureDetector(
              onTap: () {
                if(controller != null && controller!.value.isInitialized && !controller!.value.isRecordingVideo) {
                  onTakePictureButtonPressed();
                }
              },
              onLongPress: () {
                if((uploadController.userController.user.isVerified) && controller != null
                    && controller!.value.isInitialized && !controller!.value.isRecordingVideo) {
                  onVideoRecordButtonPressed();
                }
              },
              onLongPressEnd: (details) {
                if((uploadController.userController.user.isVerified) && controller != null
                    && controller!.value.isInitialized && controller!.value.isRecordingVideo) {
                  onStopButtonPressed();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isRecording ? 90 : 80,
                height: isRecording ? 90 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording ? AppColor.red : AppColor.lightGrey,
                ),
                child: isRecording ? const Icon(Icons.stop, color: Colors.white, size: 45,) : null,
              ),
            ),
          ),
        ),
        // Align(
        //   alignment: Alignment.bottomCenter,
        //   child: _thumbnailWidget(),
        // ),
    ],),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    return Listener(
      onPointerDown: (_) => _pointers++,
      onPointerUp: (_) => _pointers--,
      child: CameraPreview(
        controller!,
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleScaleUpdate,
                onTapDown: (TapDownDetails details) =>
                    onViewFinderTap(details, constraints),
              );
            }),
      )
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
  }

  // /// Display the thumbnail of the captured image or video.
  // Widget _thumbnailWidget() {
  //   final VideoPlayerController? localVideoController = videoController;
  //
  //   return Align(
  //       alignment: Alignment.centerRight,
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: <Widget>[
  //           if (localVideoController == null && imageFile == null)
  //             SizedBox.shrink()
  //           else
  //             SizedBox(
  //               width: 64.0,
  //               height: 64.0,
  //               child: (localVideoController == null)
  //                   ? (
  //                   // The captured image on the web contains a network-accessible URL
  //                   // pointing to a location within the browser. It may be displayed
  //                   // either with Image.network or Image.memory after loading the image
  //                   // bytes to memory.
  //                   kIsWeb
  //                       ? Image.network(imageFile!.path)
  //                       : Image.file(File(imageFile!.path)))
  //                   : Container(
  //                 decoration: BoxDecoration(
  //                     border: Border.all(color: Colors.pink)),
  //                 child: Center(
  //                   child: AspectRatio(
  //                       aspectRatio:
  //                       localVideoController.value.aspectRatio,
  //                       child: VideoPlayer(localVideoController)),
  //                 ),
  //               ),
  //             ),
  //         ],
  //       ),
  //
  //   );
  // }

  /// Display a bar with buttons to change the flash and exposure modes
  Widget _modeControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: flashIcon,
          color: controller?.value.flashMode == FlashMode.off
              ? AppColor.mystic : AppColor.yellow,
          onPressed: controller != null ? onFlashModeButtonPressed : null,
        ),
        if (uploadController.userController.user.isVerified) IconButton(
          icon: Icon(enableAudio ? Icons.volume_up : Icons.volume_mute),
          color: enableAudio ? AppColor.mystic : AppColor.yellow,
          onPressed: controller != null ? onAudioModeButtonPressed : null,
        ),
      ],
    );
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final CameraController cameraController = controller!;

    final Offset offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      return controller!.setDescription(cameraDescription);
    } else {
      return _initializeCameraController(cameraDescription);
    }
  }

  Future<void> _initializeCameraController(CameraDescription cameraDescription, {bool isAudioEnabled = true}) async {
    final CameraController cameraController = CameraController(cameraDescription,
      ResolutionPreset.high, enableAudio: isAudioEnabled, imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        AppUtilities.showSnackBar(message: 'Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
      await Future.wait(<Future<Object?>>[
        cameraController.getMaxZoomLevel().then((double value) => _maxAvailableZoom = value),
        cameraController.getMinZoomLevel().then((double value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          AppUtilities.showSnackBar(message: 'You have denied camera access.');
          break;
        case 'CameraAccessDeniedWithoutPrompt':
        // iOS only
          AppUtilities.showSnackBar(message: 'Please go to Settings app to enable camera access.');
          break;
        case 'CameraAccessRestricted':
        // iOS only
          AppUtilities.showSnackBar(message: 'Camera access is restricted.');
          break;
        case 'AudioAccessDenied':
          AppUtilities.showSnackBar(message: 'You have denied audio access.');
          break;
        case 'AudioAccessDeniedWithoutPrompt':
        // iOS only
          AppUtilities.showSnackBar(message: 'Please go to Settings app to enable audio access.');
          break;
        case 'AudioAccessRestricted':
        // iOS only
          AppUtilities.showSnackBar(message: 'Audio access is restricted.');
          break;
        default:
          AppUtilities.logger.e(e.toString());
          break;
      }
    }

    if (mounted) {
      setState(() {
        isDisposed = false;
      });
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((XFile? file) {
      if (mounted) {
        setState(() {
          imageFile = file;
          videoController?.dispose();
          videoController = null;
        });
      }

      if (file != null) {
        AppUtilities.logger.i('Picture saved to ${file.path}');
        uploadController.handleImage(imageFile: file);
      }
    });
  }

  void onFlashModeButtonPressed() {

    FlashMode flashMode = FlashMode.off;
    if(flashModeIndex < 3) {
      flashModeIndex++;
    } else {
      flashModeIndex = 0;
    }
    switch(flashModeIndex) {
      case 0:
        flashIcon = const Icon(Icons.flash_off);
        flashMode = FlashMode.off;
        break;
      case 1:
        flashIcon = const Icon(Icons.flash_auto);
        flashMode = FlashMode.auto;
        break;
      case 2:
        flashIcon = const Icon(Icons.flash_on);
        flashMode = FlashMode.always;
        break;
      case 3:
        flashIcon = const Icon(Icons.highlight);
        flashMode = FlashMode.torch;
        break;
      case 4:
        break;
      case 5:
        break;
    }

    onSetFlashModeButtonPressed(flashMode);
  }


  void onAudioModeButtonPressed() {
    enableAudio = !enableAudio;

    if (controller != null) {
      _initializeCameraController(controller!.description, isAudioEnabled: enableAudio);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onSetFlashModeButtonPressed(FlashMode mode) {
    setFlashMode(mode).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void onVideoRecordButtonPressed() {
    setState(() {
      isRecording = true;
    });

    startVideoRecording().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void onStopButtonPressed() {
    setState(() {
      isRecording = false;
    });

    stopVideoRecording().then((XFile? file) {
      if (mounted) {
        setState(() {});
      }

      if (file != null) {
        AppUtilities.logger.i('Video recorded to ${file.path}');
        uploadController.handleVideo(videoFile: file);
      }
    });
  }

  Future<void> onPausePreviewButtonPressed() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      AppUtilities.showSnackBar(message: 'Error: select a camera first.');
      return;
    }

    if (cameraController.value.isPreviewPaused) {
      await cameraController.resumePreview();
    } else {
      await cameraController.pausePreview();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onPauseButtonPressed() {
    pauseVideoRecording().then((_) {
      if (mounted) {
        setState(() {});
      }
      AppUtilities.showSnackBar(message: 'Video recording paused');
    });
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      if (mounted) {
        setState(() {});
      }
      AppUtilities.showSnackBar(message: 'Video recording resumed');
    });
  }

  Future<void> startVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      AppUtilities.showSnackBar(message: 'Error: select a camera first.');
      return;
    }

    if (cameraController.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return;
    }

    try {
      await cameraController.startVideoRecording();

      int maxDurationInSeconds = uploadController.userController.user.userRole == UserRole.subscriber
          ? AppConstants.verifiedMaxVideoDurationInSeconds : AppConstants.adminMaxVideoDurationInSeconds;
      Duration duration = Duration(seconds: maxDurationInSeconds);
      Timer(duration, () async {
        if (cameraController.value.isRecordingVideo) {
          onStopButtonPressed();
        }
      });

    } on CameraException catch (e) {
      AppUtilities.logger.e(e.toString());
      return;
    }
  }

  Future<XFile?> stopVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return null;
    }

    try {
      return cameraController.stopVideoRecording();
    } on CameraException catch (e) {
      AppUtilities.logger.e(e.toString());
      return null;
    }
  }

  Future<void> pauseVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return;
    }

    try {
      await cameraController.pauseVideoRecording();
    } on CameraException catch (e) {
      AppUtilities.logger.e(e.toString());
      rethrow;
    }
  }

  Future<void> resumeVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return;
    }

    try {
      await cameraController.resumeVideoRecording();
    } on CameraException catch (e) {
      AppUtilities.logger.e(e.toString());
      rethrow;
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (controller == null) {
      return;
    }

    try {
      await controller!.setFlashMode(mode);
    } on CameraException catch (e) {
      AppUtilities.logger.e(e.toString());
      rethrow;
    }
  }

  Future<void> setExposureMode(ExposureMode mode) async {
    if (controller == null) {
      return;
    }

    try {
      await controller!.setExposureMode(mode);
    } on CameraException catch (e) {
      AppUtilities.logger.e(e.toString());
      rethrow;
    }
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      AppUtilities.showSnackBar(message: 'Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      AppUtilities.logger.e(e.toString());
      return null;
    }
  }

}
