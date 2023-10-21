import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:video_trimmer/video_trimmer.dart';

import '../../../neom_posts.dart';

class StatefulTrimmerView extends StatefulWidget {

  PostUploadController uploadController;

  StatefulTrimmerView({required this.uploadController, });

  @override
  _StatefulTrimmerViewState createState() => _StatefulTrimmerViewState();
}

class _StatefulTrimmerViewState extends State<StatefulTrimmerView> {
  final Trimmer trimmer = Trimmer();
  @override
  void initState() {
    super.initState();
    loadVideo();
  }

  void loadVideo() {
    trimmer.loadVideo(videoFile: File(widget.uploadController.mediaFile.value.path));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostUploadController>(
      id: AppPageIdConstants.upload,
      init: PostUploadController(),
      builder: (_) => Obx(() {
      return Center(
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoViewer(trimmer: trimmer),
                    Center(
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
                          icon: Icon(_.isPlaying.value ? Icons.pause : Icons.play_arrow,),
                          iconSize: 30,
                          color: Colors.white70.withOpacity(0.5),
                          // onPressed: () async {
                          //   await _.playPauseVideo();
                          //     setState(() {
                          //
                          //     });
                          // },
                          onPressed: () async {
                            bool playbackState = await trimmer.videoPlaybackControl(
                              startValue: _.trimmedStartValue.value,
                              endValue: _.trimmedEndValue.value,
                            );
                            setState(() {
                              _.isPlaying.value = playbackState;
                            });
                          },
                        ),
                      ),
                    ),
                  ]
              ),
              Center(
                child: TrimViewer(
                  trimmer: trimmer,
                  viewerHeight: 50.0,
                  viewerWidth: MediaQuery.of(context).size.width,
                  maxVideoLength: const Duration(seconds: AppConstants.maxVideoDurationInSeconds),
                  onChangeStart: (value) => _.setTrimmedStart(value),
                  onChangeEnd: (value) => _.setTrimmedEnd(value),
                  onChangePlaybackState: (value) => _.setIsPlaying(value),
                  durationTextStyle: const TextStyle(fontSize: 12, color: AppColor.white),
                ),
              ),
              // ElevatedButton(
              //   onPressed: _.isUploading.value
              //       ? null
              //       : () async {
              //     _saveVideo().then((outputPath) {
              //
              //     });
              //   },
              //   child: Text("SAVE"),
              // ),
            ],
          ),
        ),);
    }),
    );

  }
}