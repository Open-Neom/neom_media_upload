import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/static/splash_page.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import '../create-post/post_widgets.dart';
import '../post_upload_controller.dart';

class TextPostPage extends StatelessWidget {
  const TextPostPage({Key? key}) : super(key: key);

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
          height:AppTheme.fullHeight(context),
          decoration: AppTheme.appBoxDecoration,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: CircleAvatar(
                      radius: AppTheme.imageRadius,
                      backgroundImage: CachedNetworkImageProvider(_.userController.profile.photoUrl)
                  ),
                  title: Text(_.userController.profile.name)
                ),
                AppTheme.heightSpace10,
              Obx(()=> _.caption.contains(AppConstants.http) ?
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding10),
                  child: TextField(
                    controller: _.captionController,
                    maxLines: _.caption.value.length < 40 ? 2 : 4,
                    maxLength: 100,
                    decoration: const InputDecoration(border: InputBorder.none),
                    onChanged: (text) => _.setCaption(text),
                  ),
                )
                : Stack (
                    children: [
                      Center(
                        child: Container(
                          width: AppTheme.fullWidth(context) * 0.95,
                          padding: const EdgeInsets.all(AppTheme.padding10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0x36FFFFFF).withOpacity(0.1),
                                const Color(0x0FFFFFFF).withOpacity(0.1)
                              ],
                              begin: FractionalOffset.topLeft,
                              end: FractionalOffset.bottomRight
                            ),
                            borderRadius: BorderRadius.circular(25)
                          ),
                          child: AutoSizeTextField(
                            controller: _.captionController,
                            textAlign: TextAlign.center,
                            minFontSize: 40,
                            maxFontSize: 60,
                            maxLines: 5,
                            maxLength: 100,
                            decoration: const InputDecoration(border: InputBorder.none),
                            onChanged: (text) => _.setCaption(text),
                          ),
                        ),
                      ),
                    ]),
              ),
              AppTheme.heightSpace10,
              const Divider(),
              AppTheme.heightSpace10,
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
                      onChanged: (text) => _.setUserLocation(text)
                    ),
                  ),
                  _.locationController.text.isNotEmpty ?
                    IconButton(
                       icon: const Icon(Icons.close),
                       onPressed: () => _.clearUserLocation(),
                    ) : Container()
                ],
              ),
              AppTheme.heightSpace10,
              const Divider(),
              AppTheme.heightSpace10,
              Obx(()=>buildLocationSuggestions(context, _),),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
