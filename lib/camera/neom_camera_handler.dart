import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:video_player/video_player.dart';

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

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  // This enum is from a different package, so a new value could be added at
  // any time. The example should keep working if that happens.
  // ignore: dead_code
  return Icons.camera;
}

void _logError(String code, String? message) {
  // ignore: avoid_print
  print('Error: $code${message == null ? '' : '\nError Message: $message'}');
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

  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;
  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    controller = widget.cameraController;
    onSetFlashModeButtonPressed(FlashMode.off);

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
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }
  // #enddocregion AppLifecycle
  bool isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        color: AppColor.main50,
        child: Column(
          children: <Widget>[
            Container(
              height: AppTheme.fullHeight(context),
              decoration: BoxDecoration(
                color: AppColor.main50,
              ),
              child: Container(
                padding: const EdgeInsets.all(1.0),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
            ),
          ],
        ),
      ),
      Align(
          alignment: Alignment.bottomCenter,
          child: _thumbnailWidget(),
      ),
      Positioned(
        bottom: 1,
        child: _modeControlRowWidget(),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: GestureDetector(
            onTap: () {
              if(controller != null && controller!.value.isInitialized && !controller!.value.isRecordingVideo) {
                onTakePictureButtonPressed();
              }
            },
            onLongPress: () {
              if(controller != null && controller!.value.isInitialized && !controller!.value.isRecordingVideo) {
                onVideoRecordButtonPressed();
              }
            },
            onLongPressEnd: (details) {
              if(controller != null && controller!.value.isInitialized && controller!.value.isRecordingVideo) {
                onStopButtonPressed();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isRecording ? 90 : 80,
              height: isRecording ? 90 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording ? Colors.red : Colors.grey,
              ),
              child: isRecording ? const Icon(Icons.stop, color: Colors.white, size: 45,) : null,
            ),
          ),
        ),
      ),
    ],);
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
      ),
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

  /// Display the thumbnail of the captured image or video.
  Widget _thumbnailWidget() {
    final VideoPlayerController? localVideoController = videoController;

    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (localVideoController == null && imageFile == null)
              Container()
            else
              SizedBox(
                width: 64.0,
                height: 64.0,
                child: (localVideoController == null)
                    ? (
                    // The captured image on the web contains a network-accessible URL
                    // pointing to a location within the browser. It may be displayed
                    // either with Image.network or Image.memory after loading the image
                    // bytes to memory.
                    kIsWeb
                        ? Image.network(imageFile!.path)
                        : Image.file(File(imageFile!.path)))
                    : Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.pink)),
                  child: Center(
                    child: AspectRatio(
                        aspectRatio:
                        localVideoController.value.aspectRatio,
                        child: VideoPlayer(localVideoController)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Display a bar with buttons to change the flash and exposure modes
  Widget _modeControlRowWidget() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: controller != null &&
                  controller!.value.isRecordingPaused
                  ? const Icon(Icons.play_arrow)
                  : const Icon(Icons.pause),
              color: Colors.blue,
              onPressed: controller != null &&
                  controller!.value.isInitialized &&
                  controller!.value.isRecordingVideo
                  ? (controller!.value.isRecordingPaused)
                  ? onResumeButtonPressed
                  : onPauseButtonPressed
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.pause_presentation),
              color:
              controller != null && controller!.value.isPreviewPaused
                  ? Colors.red
                  : Colors.blue,
              onPressed:
              controller == null ? null : onPausePreviewButtonPressed,
            ),
            IconButton(
              icon: flashIcon,
              color: controller?.value.flashMode == FlashMode.off
                  ? AppColor.mystic : AppColor.yellow,
              onPressed: controller != null ? onFlashModeButtonPressed : null,
            ),
            IconButton(
              icon: Icon(enableAudio ? Icons.volume_up : Icons.volume_mute),
              color: enableAudio ? AppColor.mystic : AppColor.yellow,
              onPressed: controller != null ? onAudioModeButtonPressed : null,
            ),
          ],
        ),
      ],
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();


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

  Future<void> _initializeCameraController(CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(cameraDescription,
      kIsWeb ? ResolutionPreset.max : ResolutionPreset.medium,
      enableAudio: enableAudio, imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
      await Future.wait(<Future<Object?>>[
        // The exposure mode is currently not supported on the web.
        ...<Future<Object?>>[],
        cameraController.getMaxZoomLevel()
            .then((double value) => _maxAvailableZoom = value),
        cameraController.getMinZoomLevel()
            .then((double value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'You have denied camera access.');
          break;
        case 'CameraAccessDeniedWithoutPrompt':
        // iOS only
          AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'Please go to Settings app to enable camera access.');
          break;
        case 'CameraAccessRestricted':
        // iOS only
          AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'Camera access is restricted.');
          break;
        case 'AudioAccessDenied':
          AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'You have denied audio access.');
          break;
        case 'AudioAccessDeniedWithoutPrompt':
        // iOS only
          AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'Please go to Settings app to enable audio access.');
          break;
        case 'AudioAccessRestricted':
        // iOS only
          AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'Audio access is restricted.');
          break;
        default:
          _showCameraException(e);
          break;
      }
    }

    if (mounted) {
      setState(() {});
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
        if (file != null) {
          AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'Picture saved to ${file.path}');
        }
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
      controller = CameraController(
        controller!.description,
        ResolutionPreset.high,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
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
        AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'Video recorded to ${file.path}');
        videoFile = file;
        _startVideoPlayer();
      }
    });
  }

  Future<void> onPausePreviewButtonPressed() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'Error: select a camera first.');
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
      AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'Video recording paused');
    });
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      if (mounted) {
        setState(() {});
      }
      AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'Video recording resumed');
    });
  }

  Future<void> startVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'Error: select a camera first.');
      return;
    }

    if (cameraController.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return;
    }

    try {
      await cameraController.startVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
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
      _showCameraException(e);
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
      _showCameraException(e);
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
      _showCameraException(e);
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
      _showCameraException(e);
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
      _showCameraException(e);
      rethrow;
    }
  }


  Future<void> _startVideoPlayer() async {
    if (videoFile == null) {
      return;
    }

    final VideoPlayerController vController = kIsWeb
    // TODO(gabrielokura): remove the ignore once the following line can migrate to
    // use VideoPlayerController.networkUrl after the issue is resolved.
    // https://github.com/flutter/flutter/issues/121927
    // ignore: deprecated_member_use
        ? VideoPlayerController.network(videoFile!.path)
        : VideoPlayerController.file(File(videoFile!.path));

    videoPlayerListener = () {
      if (videoController != null) {
        // Refreshing the state to update video player with the correct ratio.
        if (mounted) {
          setState(() {});
        }
        videoController!.removeListener(videoPlayerListener!);
      }
    };
    vController.addListener(videoPlayerListener!);
    await vController.setLooping(true);
    await vController.initialize();
    await videoController?.dispose();
    if (mounted) {
      setState(() {
        imageFile = null;
        videoController = vController;
      });
    }
    await vController.play();
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'Error: select a camera first.');
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
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    _logError(e.code, e.description);
    AppUtilities.showSnackBar(AppFlavour.appInUse.name, 'Error: ${e.code}\n${e.description}');
  }


  void takePhoto() async {
    // Logic for taking a photo
  }

}
