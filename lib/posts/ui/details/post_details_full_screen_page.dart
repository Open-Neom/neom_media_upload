import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/read_more_container.dart';
import 'package:neom_commons/neom_commons.dart';

import '../../../neom_posts.dart';

class PostDetailsFullScreenPage extends StatelessWidget {
  const PostDetailsFullScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostDetailsController>(
      id: AppPageIdConstants.postDetails,
      init: PostDetailsController(),
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main25,
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: GestureDetector(
            child: Stack(
              children: [
                InteractiveViewer(
                  child: GestureDetector(
                    child: Center(
                        child: customCachedNetworkImage(_.post.mediaUrl)
                    ),
                    onDoubleTap: () => Navigator.pop(context),
                  ),
                ),
                _.showInfo ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  width: AppTheme.fullWidth(context),
                  color: Colors.black.withOpacity(0.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(_.post.profileImgUrl.isNotEmpty ? _.post.profileImgUrl : AppFlavour.getAppLogoUrl(),),
                        ),
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
                                        color: AppColor.white80
                                    ),
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
                                onTap: () => CoreUtilities().shareAppWithPost(_.post),
                              ),
                            ]
                          ),
                          AppTheme.heightSpace10,
                          if(_.post.caption.isNotEmpty)
                            ReadMoreContainer(text: _.post.caption,
                              fontSize: 14, trimLines: 6, letterSpacing: 0.1, padding: 0,
                            ),
                          AppTheme.heightSpace10,
                          GestureDetector(
                              onTap: () => Get.toNamed(AppRouteConstants.postComments, arguments: _.post),
                              child: Text(_.post.comments.isNotEmpty ? AppTranslationConstants.seeComments.tr
                                  : AppTranslationConstants.writeComment.tr,
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  color: AppColor.white80,
                                  fontSize: 15,
                                ),
                              )
                          ),
                          AppTheme.heightSpace10,
                        ])
                    ) : const SizedBox.shrink()
                    ]),
                ) : const SizedBox.shrink(),
              ],
            ),
            onTap: () => _.showPostInfo(!_.showInfo),
            onDoubleTap: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

}
