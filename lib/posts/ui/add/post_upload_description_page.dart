
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
import 'package:video_player/video_player.dart';

import 'create_post/post_widgets.dart';
import 'post_upload_controller.dart';

class PostUploadDescriptionPage extends StatelessWidget {
  const PostUploadDescriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostUploadController>(
      id: AppPageIdConstants.upload,
      init: PostUploadController(),
      builder: (_) => Obx(()=> Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColor.main50,
        appBar: !_.isUploading.value ? AppBar(
          backgroundColor: AppColor.appBar,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _.getBackToUploadImage(context),
          ),
          title: Text(AppTranslationConstants.newPost.tr),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.check, size: 30, color: AppColor.mystic),
              onPressed: () async => {
                if(!_.isButtonDisabled.value) await _.handleSubmit(),
              },
            ),
          ],
        ) : null,
        body: _.isLoading.value ? const Center(child: CircularProgressIndicator())
        : _.isUploading.value ? const SplashPage()
        : Container(
          decoration: AppTheme.appBoxDecoration,
          height: AppTheme.fullHeight(context),
          child: Column(
            children: <Widget>[
              ListTile(
                  leading: CircleAvatar(
                      radius: 15,
                      backgroundImage: CachedNetworkImageProvider(_.userController.profile.photoUrl)
                  ),
                  title: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.padding10,
                    ),
                    child: Text(_.profile.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  )
              ),
              buildPostDescriptionWidget(_),
              AppTheme.heightSpace10,
              if(_.postType == PostType.image) Center(
                child: AspectRatio(
                  aspectRatio: AppTheme.landscapeAspectRatio,
                  child: fileImage(_.croppedImageFile.value.path),
                ),
              ) else if(_.postType == PostType.video && _.videoPlayerController != null) Container(
                color: AppColor.appBlack,
                height: AppTheme.fullWidth(context)/(_.videoPlayerController!.value.aspectRatio > 1 ? _.videoPlayerController!.value.aspectRatio : 1),
                width: AppTheme.fullWidth(context)*(_.videoPlayerController!.value.aspectRatio <= 1 ? _.videoPlayerController!.value.aspectRatio : 1),
                child: Stack(
                children: [
                  VideoPlayer(_.videoPlayerController!),
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
                        onPressed: () => _.playPauseVideo(),
                      ),
                    ),
                  ),
                ]),
              ),
              AppTheme.heightSpace10,
              buildLocationWidget(_, context),
              AppTheme.heightSpace20,
              buildLocationSuggestions(context, _)
            ],
          ),
        ),
      ),),
    );
  }

  Row buildLocationWidget(PostUploadController _, BuildContext context) {
    return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AppTheme.widthSpace10,
                const Icon(Icons.pin_drop,size: 20.0,),
                AppTheme.widthSpace10,
                Expanded(child: TextFormField(
                  controller: _.locationController,
                  onTap:() => _.getLocation(context) ,
                  decoration: InputDecoration(
                    filled: false,
                    labelText: AppTranslationConstants.wherePhotoTaken.tr,
                    // border: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(10),
                    // ),
                  ),
                ),),
                _.locationController.text.isNotEmpty ?
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _.clearUserLocation(),
                ) : const SizedBox.shrink()
              ],
            );
  }

  Widget buildPostDescriptionWidget(PostUploadController _) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.padding10,
      ),
      // decoration: BoxDecoration(
      //     gradient: LinearGradient(
      //         colors: [
      //           const Color(0x36FFFFFF).withOpacity(0.1),
      //           const Color(0x0FFFFFFF).withOpacity(0.1)
      //         ],
      //         begin: FractionalOffset.topLeft,
      //         end: FractionalOffset.bottomRight
      //     ),
      //     borderRadius: BorderRadius.circular(25)
      // ),
      child: HashTagTextField(
        decoratedStyle: const TextStyle(color: AppColor.dodgetBlue),
        keyboardType: TextInputType.multiline,
        controller: _.captionController,
        decoration: InputDecoration(
          hintText: AppTranslationConstants.writeCaption.tr,
          border: InputBorder.none,
        ),
        minLines: 2,
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
    );
  }
}
