import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/domain/model/post.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import '../blog_editor_controller.dart';

Widget buildBlogEntryList(Iterable<Post> blogEntries) {
  return ListView.builder(
    itemCount: blogEntries.length,
    itemBuilder: (context, index) {
      Post blogEntry = blogEntries.elementAt(index);
      List<String> blogEntryCaptionSplitted = blogEntry.caption.split(AppConstants.titleTextDivider);
      String title = "";
      String entry = "";

      if(blogEntryCaptionSplitted.isNotEmpty) {
        if(blogEntryCaptionSplitted.length > 1) {
          title = blogEntryCaptionSplitted[0];
          entry = blogEntryCaptionSplitted[1];
        } else {
          entry = blogEntryCaptionSplitted[0];
        }
      }
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        // leading: SizedBox(
        //     width: 50,
        //     child: blogEntry.thumbnailUrl.isNotEmpty
        //         ? CachedNetworkImage(imageUrl: blogEntry.thumbnailUrl)
        //         : SizedBox.shrink()
        // ),
        title: Row(
            children: <Widget>[
              Text(title.length > AppConstants.maxItemlistNameLength
                  ? "${title.substring(0,AppConstants.maxItemlistNameLength)}..."
                  : title, style: const TextStyle(fontWeight: FontWeight.w600),),
            ]),
        subtitle: Text(entry, maxLines: 3,),
        trailing: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => {
              if(blogEntry.isDraft) {
                Get.toNamed(AppRouteConstants.blogEditor, arguments: [blogEntry])
              } else {
                Get.toNamed(AppRouteConstants.blogEntry, arguments: [blogEntry])
              }
            },
            icon: const Icon(Icons.arrow_forward_ios_outlined)
        ),
        onTap: () => {
          if(blogEntry.isDraft) {
            Get.toNamed(AppRouteConstants.blogEditor, arguments: [blogEntry])
          } else {
            Get.toNamed(AppRouteConstants.blogEntry, arguments: [blogEntry])
          }
        },
        onLongPress: () => {
          Get.toNamed(AppRouteConstants.blogEditor, arguments: [blogEntry])
        },
      );
    }
  );
}


Widget blogLikeCommentShare(BlogEditorController _) {
  return Container(
      color: AppColor.main75,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                      onLongPress: () => Get.toNamed(AppRouteConstants.likedProfiles, arguments: _.blogEntry.value.likedProfiles),
                      onPressed: () async => _.handleLikePost(),
                      child: Row(
                        children: <Widget>[
                          Icon(_.isLiked.value ? FontAwesomeIcons.solidHeart
                            :  FontAwesomeIcons.heart,
                            size: AppTheme.postIconSize,
                            color: AppColor.white80),
                          AppTheme.widthSpace5,
                          Text('${_.blogEntry.value.likedProfiles.length}',
                            style: const TextStyle(color: AppColor.white),
                          ),
                        ],
                      )
                  ),
                  TextButton(
                      onPressed: () => Get.toNamed(AppRouteConstants.postComments, arguments: _.blogEntry.value),
                      child: Row(
                        children: <Widget>[
                          Icon(_.blogEntry.value.commentIds.isNotEmpty
                              ? _.postDetailController.verifyIfCommented(_.blogEntry.value.commentIds, _.profile.value.comments ?? [])
                              ? FontAwesomeIcons.solidMessage
                              : FontAwesomeIcons.message
                              : FontAwesomeIcons.message,
                              size: AppTheme.postIconSize,
                              color: AppColor.white80),
                          AppTheme.widthSpace5,
                          Text(_.blogEntry.value.commentIds.length.toString(),
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
                      CoreUtilities().shareAppWithPost(_.blogEntry.value);
                    },
                  ),
                ]
            ),
            TextButton(
                onPressed: () => Get.toNamed(AppRouteConstants.postComments,
                    arguments: _.blogEntry.value),
                child: Text(AppTranslationConstants.seeComments.tr,
                  style: const TextStyle(
                    color: AppColor.white,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                )
            ),
          ]
      )
  );
}
