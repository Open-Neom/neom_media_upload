
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import 'package:neom_commons/core/ui/static/splash_page.dart';
import 'package:neom_commons/core/ui/widgets/custom_image.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/post_type.dart';

import '../widgets/stateful_trimmer_view.dart';
import 'create-post/post_widgets.dart';
import 'post_upload_controller.dart';

class PostUploadDescriptionPage extends StatelessWidget {
  const PostUploadDescriptionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostUploadController>(
      id: AppPageIdConstants.upload,
      init: PostUploadController(),
      builder: (_) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColor.main50,
        appBar: AppBar(
          backgroundColor: AppColor.appBar,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _.getBackToUploadImage(context),
          ),
          title: Text(AppTranslationConstants.newPost.tr),
          actions: <Widget>[
            _.isUploading.value ? Container() : IconButton(
              icon: const Icon(Icons.check, size: 30, color: AppColor.mystic),
              onPressed: () async => {
                if(!_.isButtonDisabled.value) await _.handleSubmit(),
              },
            ),
          ],
        ),
        body: _.isLoading.value ? const Center(child: CircularProgressIndicator())
        : _.isUploading.value ? const SplashPage()
        : Container(
          decoration: AppTheme.appBoxDecoration,
          height: AppTheme.fullHeight(context),
          child: Column(
            children: <Widget>[
              if(_.postType == PostType.image) Center(
                child: AspectRatio(
                  aspectRatio: AppTheme.landscapeAspectRatio,
                  child: fileImage(_.croppedImageFile.value.path)
              ///DEPRECATED
              // Stack(
              //     children: [
              //       VideoPlayer(_.videoPlayerController),
              //
              //       Center(
              //         child: Container(
              //           decoration: BoxDecoration(
              //               gradient: LinearGradient(
              //                   colors: [
              //                     const Color(0x36FFFFFF).withOpacity(0.1),
              //                     const Color(0x0FFFFFFF).withOpacity(0.1)
              //                   ],
              //                   begin: FractionalOffset.topLeft,
              //                   end: FractionalOffset.bottomRight
              //               ),
              //               borderRadius: BorderRadius.circular(50)
              //           ),
              //           child: IconButton(
              //             icon: Icon(_.isPlaying.value ? Icons.pause : Icons.play_arrow,),
              //             iconSize: 30,
              //             color: Colors.white70.withOpacity(0.5),
              //             onPressed: () => _.playPauseVideo(),
              //             // onPressed: () {
              //             //   Navigator.of(context).push(
              //             //     MaterialPageRoute(builder: (context) {
              //             //       return TrimmerView(File(_.mediaFile.value.path));
              //             //     }),
              //             //   );
              //             // },
              //           ),
              //         ),
              //       ),
              //     ]),
                ),
              ),
              // TrimmerView(),
              if(_.postType == PostType.video) StatefulTrimmerView(uploadController: _),
              AppTheme.heightSpace10,
              ListTile(
                leading: CircleAvatar(
                  radius: 15,
                  backgroundImage: CachedNetworkImageProvider(_.userController.profile.photoUrl)
                ),
                title: SizedBox(
                  width: 250.0,
                  child: HashTagTextField(
                    decoratedStyle: const TextStyle(color: AppColor.dodgetBlue),
                    keyboardType: TextInputType.multiline,
                    controller: _.captionController,
                    decoration: InputDecoration(
                    hintText: AppTranslationConstants.writeCaption.tr,
                    border: InputBorder.none,
                    ),
                    minLines: 3,
                    maxLines: 10,
                    /// Called when detection (word starts with #, or # and @) is being typed
                    onDetectionTyped: (text) {
                      AppUtilities.logger.t(text);
                    },
                    /// Called when detection is fully typed
                    onDetectionFinished: () {
                      AppUtilities.logger.t("Type Detection Finished");
                    },
                  ),
                )
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Icon(Icons.pin_drop,size: 20.0,),
                  SizedBox(
                    width: 250.0,
                    child: TextField(
                      controller: _.locationController,
                      decoration: InputDecoration(
                        hintText: AppTranslationConstants.wherePhotoTaken.tr,
                        border: InputBorder.none,
                      ),
                      onChanged: (text) => _.updatePage()
                    ),
                  ),
                  _.locationController.text.isNotEmpty ?
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _.clearUserLocation(),
                  ) : Container()
                ],
              ),
              const Divider(),
              Obx(()=>buildLocationSuggestions(context, _),),
            ],
          ),
        ),
      ),
    );
  }
}
