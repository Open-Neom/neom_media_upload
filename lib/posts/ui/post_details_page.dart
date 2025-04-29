import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/core/ui/widgets/handled_cached_network_image.dart';
import 'package:neom_commons/core/ui/widgets/read_more_container.dart';

import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import '../../neom_posts.dart';
import 'post_details_controller.dart';

class PostDetailsPage extends StatelessWidget {

  const PostDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    //TODO VERIFY ITS WORKING
    Get.delete<PostDetailsController>();

    return GetBuilder<PostDetailsController>(
      id: AppPageIdConstants.postDetails,
      init: PostDetailsController(),
      builder: (_) => SafeArea(
        child: Scaffold(
            backgroundColor: AppColor.main50,
            body: Obx(()=> _.isLoading.value ? const AppCircularProgressIndicator()
                : Container(
              decoration: AppTheme.appBoxDecoration,
              height: AppTheme.fullHeight(context),
              child: SingleChildScrollView(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if(_.showInfo) ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(_.post.profileImgUrl.isNotEmpty ? _.post.profileImgUrl : AppFlavour.getAppLogoUrl(),),),
                    title: GestureDetector(
                      child: Text(CoreUtilities.capitalizeFirstLetter(_.post.profileName),
                        style: const TextStyle(fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      onTap: () {
                        _.userController.profile.id == _.post.ownerId
                            ? Get.toNamed(AppRouteConstants.profileDetails,
                            arguments: _.userController.profile.id)
                            : Get.toNamed(AppRouteConstants.mateDetails,
                            arguments: _.post.ownerId);
                        },
                    ),
                    subtitle: Text(_.post.location),
                      // trailing: const Icon(Icons.more_vert),
                  ),
                  GestureDetector(
                    child: HandledCachedNetworkImage(_.post.mediaUrl),
                    ///Activate when interaction is fullscren and not in container size
                    // onTap: () => _.showPostInfo(_.showInfo ? false : true),
                    onDoubleTap: () => Navigator.pop(context),
                  ),
                  _.showInfo ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: <Widget>[
                                GestureDetector(
                                  child: Row(
                                    children: <Widget>[
                                      Icon(_.isLikedPost(_.post) ? FontAwesomeIcons.solidHeart :  FontAwesomeIcons.heart,
                                          size: 23,
                                          color: AppColor.white80
                                      ),
                                      AppTheme.widthSpace5,
                                      Text('${_.post.likedProfiles.length}',
                                        style: const TextStyle(color: AppColor.white),
                                      )
                                    ],
                                  ),
                                  onLongPress: () => Get.toNamed(AppRouteConstants.likedProfiles, arguments: _.post.likedProfiles),
                                  onTap: () async => _.handleLikePost(_.post),
                                ),
                                AppTheme.widthSpace15,
                                GestureDetector(
                                  child: Row(
                                    children: <Widget>[
                                      Icon(_.post.commentIds.isNotEmpty
                                          ? _.verifyIfCommented(_.post.commentIds, _.profile.comments ?? [])
                                          ? FontAwesomeIcons.solidMessage : FontAwesomeIcons.message : FontAwesomeIcons.message,
                                          size: AppTheme.postIconSize,
                                          color: AppColor.white80),
                                      AppTheme.widthSpace5,
                                      Text(_.post.commentIds.length.toString(),
                                        style: const TextStyle(color: AppColor.white),
                                      )
                                    ],
                                  ),
                                  onTap: () => Get.toNamed(AppRouteConstants.postComments, arguments: _.post),
                                ),
                                AppTheme.widthSpace15,
                                GestureDetector(
                                  child: const Icon(FontAwesomeIcons.share,
                                      size: AppTheme.postIconSize,
                                      color: AppColor.white
                                  ),
                                  onTap: () {
                                    CoreUtilities().shareAppWithPost(_.post);
                                    },
                                ),
                              ]
                            ),
                            AppTheme.heightSpace10,
                            if(_.post.caption.isNotEmpty)
                              ReadMoreContainer(text: _.post.caption,
                                fontSize: 14, trimLines: 3, letterSpacing: 0.1, padding: 0,
                              ),
                            AppTheme.heightSpace5,
                            GestureDetector(
                                onTap: () => Get.toNamed(AppRouteConstants.postComments, arguments: _.post),
                                child: Text(_.post.comments.isNotEmpty ? AppTranslationConstants.seeComments.tr
                                    : AppTranslationConstants.writeComment.tr,
                                  textAlign: TextAlign.justify,
                                  style: const TextStyle(
                                    color: AppColor.white,
                                    fontSize: 15,
                                    decoration: TextDecoration.underline,
                                  ),
                                )
                            ),
                            if(_.post.comments.isNotEmpty) Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:[
                                AppTheme.heightSpace5,
                                Row(
                                  children: [
                                    GestureDetector(
                                      child: Text(_.post.comments.first.ownerName,
                                        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      onTap: () {
                                        _.userController.profile.id == _.post.comments.first.ownerId
                                            ? Get.toNamed(AppRouteConstants.profileDetails,
                                            arguments: _.userController.profile.id)
                                            : Get.toNamed(AppRouteConstants.mateDetails,
                                            arguments: _.post.comments.first.ownerId);
                                      },
                                    ),
                                    AppTheme.widthSpace5,
                                    Text(AppUtilities.getTimeAgo(_.post.comments.first.createdTime, showShort: false),
                                      style: const TextStyle(fontSize: 13, color: Colors.white), locale: Get.locale,
                                    ),
                                  ],
                                ),
                                Text(_.post.comments.first.text,
                                  style: const TextStyle(fontSize: 14, color: Colors.white),
                                ),
                              ]
                            ),
                          ]
                        )
                    ) : const SizedBox.shrink()
                  ],
                ),),
              ),
            )
          ),
      ),
    );
  }
}
