import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:hashtagable_v3/hashtagable.dart';

import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'post_details_controller.dart';

class PostDetailsPage extends StatelessWidget {

  const PostDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //TODO VERIFY ITS WORKING
    Get.delete<PostDetailsController>();

    return GetBuilder<PostDetailsController>(
      id: AppPageIdConstants.postDetails,
      init: PostDetailsController(),
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main50,
        body: SingleChildScrollView(
          child: Container(
            decoration: AppTheme.boxDecoration,
            child: Obx(()=> _.isLoading.value ? const Center(child: CircularProgressIndicator())
                : InteractiveViewer(
              onInteractionStart: (scale) => {
                if(scale.pointerCount > 1) {
                  _.showPostInfo(false)
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    child: Center(
                      child: CachedNetworkImage(imageUrl: _.post.mediaUrl)
                    ),
                    onTap: () {
                      if(_.showInfo) {
                        _.showPostInfo(false);
                      } else {
                        _.showPostInfo(true);
                      }
                    },
                    onDoubleTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _.showInfo ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            TextButton(
                                onLongPress: () => Get.toNamed(AppRouteConstants.likedProfiles, arguments: _.post.likedProfiles),
                                onPressed: () async => _.handleLikePost(_.post),
                                child: Row(
                                  children: <Widget>[
                                    Icon(_.isLikedPost(_.post) ? FontAwesomeIcons.solidHeart
                                        :  FontAwesomeIcons.heart,
                                        size: AppTheme.postIconSize,
                                        color: AppColor.white80
                                    ),
                                    AppTheme.widthSpace5,
                                    Text('${_.post.likedProfiles.length}',
                                      style: const TextStyle(color: AppColor.white),
                                    )
                                  ],
                                )
                            ),
                            TextButton(
                                onPressed: () => Get.toNamed(AppRouteConstants.postComments, arguments: _.post),
                                child: Row(
                                  children: <Widget>[
                                    Icon(_.post.commentIds.isNotEmpty
                                        ? _.verifyIfCommented(_.post.commentIds, _.profile.comments ?? [])
                                        ? FontAwesomeIcons.solidMessage
                                        : FontAwesomeIcons.message
                                        : FontAwesomeIcons.message,
                                        size: AppTheme.postIconSize,
                                        color: AppColor.white80),
                                    AppTheme.widthSpace5,
                                    Text(_.post.commentIds.length.toString(),
                                      style: const TextStyle(color: AppColor.white),
                                    )
                                  ],
                                )
                            ),
                            IconButton(
                              icon: const Icon(FontAwesomeIcons.share,
                                  size: AppTheme.postIconSize,
                                  color: AppColor.white
                              ),
                              onPressed: () {
                                CoreUtilities().shareAppWithPost(_.post);
                              },
                            ),
                          ]
                      ),
                          AppTheme.heightSpace10,
                          TextButton(
                            child: Text("@${_.post.profileName}",
                            style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.bold
                            ),
                            ),
                            onPressed: () => {
                              _.userController.profile.id == _.post.ownerId
                              ? Get.toNamed(AppRouteConstants.profileDetails,
                                arguments: _.userController.profile.id)
                              : Get.toNamed(AppRouteConstants.mateDetails,
                                arguments: _.post.ownerId)
                            },
                          ),
                          Visibility(
                              visible: _.post.caption.isNotEmpty,
                              child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding10),
                                  child: (_.post.caption.contains("http") || _.post.caption.contains("https"))
                                      ?
                                  Linkify(
                                    onOpen: (link)  {
                                      CoreUtilities.launchURL(link.url);
                                    },
                                    text: _.post.caption,
                                    textAlign: TextAlign.justify,
                                    style: const TextStyle(fontSize: 15, ),
                                    linkStyle: const TextStyle(fontSize: 16, color: AppColor.dodgetBlue),
                                  ) :
                                  HashTagText(
                                    text: _.post.caption,
                                    softWrap: true,
                                    basicStyle: const TextStyle(fontSize: 15),
                                    decoratedStyle: const TextStyle(fontSize: 15, color: AppColor.dodgetBlue),
                                    onTap: (text) {
                                      AppUtilities.logger.e(text);
                                    },
                                  )
                              )
                          ),
                          TextButton(
                              onPressed: () => Get.toNamed(AppRouteConstants.postComments,
                                  arguments: _.post),
                              child: Text(AppTranslationConstants.seeComments.tr,
                                textAlign: TextAlign.justify,
                                style: const TextStyle(
                                  color: AppColor.white,
                                  fontSize: 18,
                                  decoration: TextDecoration.underline,
                                ),
                              )
                          ),
                        ]
                      )
                  ) : Container()
                ],
              )
            ),),
          ),
        )
      ),
    );
  }
}
