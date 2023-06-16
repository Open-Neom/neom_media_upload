import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';

import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'post_upload_controller.dart';

class PostUploadPage extends StatelessWidget {
  const PostUploadPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostUploadController>(
      id: AppPageIdConstants.upload,
      init: PostUploadController(),
      builder: (_) {
         return Scaffold(
           extendBodyBehindAppBar: true,
           appBar: AppBarChild(color: Colors.transparent),
           body: Container(
              decoration: AppTheme.appBoxDecoration,
              child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  child: Column(children: [
                    Image.asset(AppAssets.uploadVector, width: 300, height: 300, fit: BoxFit.fill,),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        AppTranslationConstants.tapToUploadImage.tr,
                          style: const TextStyle(
                            fontSize: 20.0,
                          ),
                        ),
                      ),  
                    ],
                  ),
                  onTap: ()=> _.handleImage()
                    //TODO Once frontal camera is repaired
                    // showDialog(
                    //   context: context,
                    //   builder: (context){
                    //     return SimpleDialog(
                    //       backgroundColor: AppTheme.canvasColor75(context),
                    //       title: Text(AppTranslationConstants.createPost.tr),
                    //       children: <Widget>[
                    //         SimpleDialogOption(
                    //           child: Text(
                    //               AppTranslationConstants.takePhoto.tr
                    //           ),
                    //           onPressed: () => _.handleImage(AppFileFrom.Camera),
                    //         ),
                    //         SimpleDialogOption(
                    //           child: Text(
                    //               AppTranslationConstants.photoFromGallery.tr
                    //           ),
                    //           onPressed: () => _.handleImage(AppFileFrom.Gallery),
                    //         ),
                    //         //TODO Once we know we have budget to upload multimedia content
                    //         // SimpleDialogOption(
                    //         //   child: Text(
                    //         //       AppTranslationConstants.videoFromGallery.tr
                    //         //   ),
                    //         //   onPressed: () => _.handleVideo(AppFileFrom.Gallery),
                    //         // ),
                    //         SimpleDialogOption(
                    //           child: Text(
                    //               AppTranslationConstants.cancel.tr
                    //           ),
                    //           onPressed: () => Get.back()
                    //         ),
                    //       ],
                    //     );
                    //   }
                    // ),
                  ),
                ],
                ),
              ),
           ),
        );
      }
    );
  }
}
