import 'dart:io';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:video_editor/video_editor.dart';

import '../../../neom_posts.dart';
import 'video_crop_page.dart';
import 'video_export_result.dart';
import 'video_export_service.dart';

class StatefulVideoEditor extends StatefulWidget {
  const StatefulVideoEditor({super.key, required this.file});

  final File file;

  @override
  State<StatefulVideoEditor> createState() => _StatefulVideoEditorState();
}

class _StatefulVideoEditorState extends State<StatefulVideoEditor> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final double height = 60;

  late final VideoEditorController _controller;
  XFile editedVideo = XFile('');
  int startTrim = 0;
  int endTrim = 0;
  bool hadChanges = false;

  PostUploadController? uploadController;


  @override
  void initState() {
    super.initState();

    final userController = Get.find<UserController>();
    int maxDurationInSeconds = userController.user!.userRole == UserRole.subscriber
        ? AppConstants.verifiedMaxVideoDurationInSeconds : AppConstants.adminMaxVideoDurationInSeconds;

    _controller = VideoEditorController.file(
        widget.file,
        minDuration: const Duration(seconds: 1),
        maxDuration: Duration(seconds: maxDurationInSeconds),
        trimStyle: TrimSliderStyle(
          onTrimmedColor: AppColor.bondiBlue,
          lineColor: AppColor.bondiBlue,
          iconColor: AppColor.white
        ),
    );
    _controller.initialize(aspectRatio: 9 / 16)
        .then((_) {
          _controller.video.play();
          setState(() {

          });
        }).catchError((error) {
          // handle minumum duration bigger than video duration error
      Navigator.pop(context);
    }, test: (e) => e is VideoMinDurationError);

    if (Get.isRegistered<PostUploadController>()) {
      uploadController = Get.find<PostUploadController>();
    } else {
      uploadController = PostUploadController();
      Get.put(uploadController);
    }
  }

  @override
  void dispose() async {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    // ExportService.dispose();
    super.dispose();
  }


  void processVideo() async {
    AppUtilities.logger.d('Processing video from path ${_controller.file.path}');
    _exportingProgress.value = 0;
    _isExporting.value = true;
    await _controller.video.pause();

    VideoFFmpegVideoEditorConfig config = VideoFFmpegVideoEditorConfig(_controller,);
    // FFmpegVideoEditorExecute execute = await config.getExecuteConfig();
    // await config.getExecuteConfig().then((value) {
    //
    //
    // });

    File editedFile = File('');
    await ExportService.runFFmpegCommand(
      await config.getExecuteConfig(),
      onProgress: (stats) {
        _exportingProgress.value = config.getFFmpegProgress(stats.getTime().ceil());
      },
      onError: (e, s) => AppUtilities.showSnackBar(message: "Error on export video :("),
      onCompleted: (file) {
        _isExporting.value = false;
        if (!mounted) return;
        editedFile = file;

        if(editedFile.path.isNotEmpty) {
          editedVideo = XFile(editedFile.path);
          if (editedVideo != null) {
            AppUtilities.logger.i('Video recorded to ${editedVideo.path}');
            hadChanges = false;
            uploadController?.setProcessedVideo(editedVideo);
          }
        }
      },
    );

      // format: VideoExportFormat.gif,
      // commandBuilder: (config, videoPath, outputPath) {
      //   final List<String> filters = config.getExportFilters();
      //   filters.add('hflip'); // add horizontal flip

      //   return '-i $videoPath ${config.filtersCmd(filters)} -preset ultrafast $outputPath';
      // },


    // await ExportService.runFFmpegCommand(
    //   await config.getExecuteConfig(),
    //   onProgress: (stats) {
    //     _exportingProgress.value = config.getFFmpegProgress(stats.getTime());
    //   },
    //   onError: (e, s) => _showErrorSnackBar("Error on export video :("),
    //   onCompleted: (file) {
    //     _isExporting.value = false;
    //     if (!mounted) return;
    //
    //     showDialog(
    //       context: context,
    //       builder: (_) => VideoResultPopup(video: file),
    //     );
    //   },
    // );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColor.getMain(),
            title: Text(AppFlavour.appInUse.name.capitalize),
            content:  Text(AppTranslationConstants.wantToCloseEditor.tr),
            actions: <Widget>[
              TextButton(
                child: Text(AppTranslationConstants.no.tr,
                  style: const TextStyle(color: AppColor.white),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(AppTranslationConstants.yes.tr,
                  style: const TextStyle(color: AppColor.white),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              )
            ],
          ),
        )) ?? false;
      },
      child: Scaffold(
        backgroundColor: AppColor.main50,
        appBar: AppBarChild(
            title: (AppTranslationConstants.videoEditor.tr),
            actionWidgets: getAppBarActions()),
        body: _controller.initialized
            ? Container(
            height: AppTheme.fullHeight(context),
            decoration: AppTheme.appBoxDecoration,
            child: Column(
              children: [
                Container(
                  height: AppTheme.fullHeight(context)/2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CropGridViewer.preview(controller: _controller),
                      AnimatedBuilder(
                        animation: _controller.video,
                        builder: (_, __) => AnimatedOpacity(
                          opacity: _controller.isPlaying ? 0 : 1,
                          duration: kThemeAnimationDuration,
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [
                                        const Color(0x36FFFFFF).withOpacity(0.1),
                                        const Color(0x0FFFFFFF).withOpacity(0.1)
                                      ],
                                      begin: FractionalOffset.topLeft,
                                      end: FractionalOffset.bottomRight
                                  ),
                                  borderRadius: BorderRadius.circular(50)
                              ),
                              child: IconButton(
                                icon: Icon(_controller.isPlaying ? Icons.pause : Icons.play_arrow,),
                                iconSize: 30,
                                color: Colors.white70.withOpacity(0.5),
                                onPressed: () => _controller.video.play(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: _trimSlider(),
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: _isExporting,
                  builder: (_, bool export, Widget? child) =>
                      AnimatedSize(
                        duration: kThemeAnimationDuration,
                        child: export ? child : null,
                      ),
                  child: AlertDialog(
                    title: ValueListenableBuilder(
                      valueListenable: _exportingProgress,
                      builder: (_, double value, __) => Text(
                        '${AppTranslationConstants.processingVideo.tr} ${(value * 100).ceil()}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    backgroundColor: AppColor.bondiBlue,
                  ),
                )
              ],
            ),
        ) : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget getLeadingAction() {
    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.close),
      tooltip: AppTranslationConstants.leaveVideoEditor,
    );
  }

  List<Widget> getAppBarActions() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        IconButton(
          onPressed: () {
            hadChanges = true;
            Navigator.push(context,
              MaterialPageRoute<void>(
                builder: (context) => CropPage(controller: _controller),
              ),
            );
          },
          icon: const Icon(Icons.crop),
          tooltip: AppTranslationConstants.openCropPage.tr,
        ),
          IconButton(
            onPressed: () async {
              if(hadChanges) {
                processVideo();
              } else {
                uploadController?.setProcessedVideo(editedVideo);
              }

            },
            icon: const Icon(Icons.arrow_forward),
            tooltip: AppTranslationConstants.processVideo.tr,
          ),
      ],),

    ];
  }

  List<Widget> _trimSlider() {
    return [
      AnimatedBuilder(
        animation: Listenable.merge([
          _controller,
          _controller.video,
        ]),
        builder: (_, __) {
          final int duration = _controller.videoDuration.inSeconds;
          final double pos = _controller.trimPosition * duration;

          if(startTrim != _controller.startTrim.inMilliseconds) {
            startTrim = _controller.startTrim.inMilliseconds;
            hadChanges = true;
          }

          if(endTrim != _controller.endTrim.inMilliseconds) {
            endTrim = _controller.endTrim.inMilliseconds;
            hadChanges = true;
          }

          return Container(
            width: AppTheme.fullWidth(context),
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
                children: [
                  Text('${AppUtilities.getDurationInMinutes(Duration(seconds: pos.toInt()).inMilliseconds)} / ${AppUtilities.getDurationInMinutes(endTrim)}',),
                  const Expanded(child: SizedBox()),
                  AnimatedOpacity(
                    opacity: _controller.isTrimming ? 1 : 0,
                    duration: kThemeAnimationDuration,
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppUtilities.getDurationInMinutes(endTrim-startTrim)),
                        ]
                    ),
                  ),
                ]
            ),
          );
        },
      ),
      Container(
        width: AppTheme.fullWidth(context),
        margin: EdgeInsets.symmetric(vertical: 10),
        child: TrimSlider(
          controller: _controller,
          horizontalMargin: 10,
          child: TrimTimeline(
            controller: _controller,
            padding: const EdgeInsets.only(top: 10),
          ),
        ),
      )
    ];
  }


}

