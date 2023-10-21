import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_file_from.dart';
import '../../../camera/neom_camera_handler.dart';
import 'post_upload_controller.dart';

class PostUploadPage extends StatelessWidget {
  const PostUploadPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostUploadController>(
      id: AppPageIdConstants.upload,
      init: PostUploadController(),
      builder: (_) {
        List<Widget> actionWidgets = [
          IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.image_outlined),
              color: Colors.white70,
              onPressed: ()=> _.handleImage()
          ),
          IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.camera_alt_outlined),
              color: Colors.white70,
              onPressed: ()=> {
                Get.toNamed(AppRouteConstants.feedActivity)
              }
          ),
        ];
         return MaterialApp(
            theme: ThemeData.dark(),
        home: Scaffold(
           // extendBodyBehindAppBar: true,
           appBar: AppBarChild(title: AppTranslationConstants.createPost.tr, ),
           backgroundColor: AppColor.main50,
           body: Obx(()=> Container(
              decoration: AppTheme.appBoxDecoration,
              child: (_.takePhoto.value) ? NeomCameraHandler(cameraController: _.cameraController,) : Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  child: Column(children: [
                    Image.asset(AppAssets.uploadVector, width: AppTheme.fullWidth(context)*0.66, fit: BoxFit.fitWidth,),
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
                  onTap: ()=>
                      // _.handleImage()
                    // TODO Once frontal camera is repaired
                    showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          backgroundColor: AppColor.getMain(),
                          title: Text(AppTranslationConstants.createPost.tr),
                          children: <Widget>[
                            SimpleDialogOption(
                              child: Text(
                                  AppTranslationConstants.takePhoto.tr
                              ),
                              onPressed: () => _.handleImage(appFileFrom: AppFileFrom.camera, context: context),
                            ),
                            SimpleDialogOption(
                              child: Text(
                                  AppTranslationConstants.photoFromGallery.tr
                              ),
                              onPressed: () => _.handleImage(),
                            ),
                            //TODO Once we know we have budget to upload multimedia content
                            SimpleDialogOption(
                              child: Text(
                                  AppTranslationConstants.videoFromGallery.tr
                              ),
                              onPressed: () => _.handleVideo(),
                            ),
                            SimpleDialogOption(
                              child: Text(
                                  AppTranslationConstants.cancel.tr
                              ),
                              onPressed: () => Navigator.pop(context)
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                ],
                ),
              ),
           ),),),
        );
      }
    );
  }
}
