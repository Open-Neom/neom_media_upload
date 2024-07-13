// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/hashtag_link_text.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:neom_timeline/neom_timeline.dart';
import 'post_comments_controller.dart';

Widget othersComment(BuildContext context, PostCommentsController _, PostComment comment) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      GestureDetector(
        onTap: () => _.profile.id == comment.ownerId ? Get.toNamed(AppRouteConstants.profile)
            : Get.toNamed(AppRouteConstants.mateDetails, arguments: comment.ownerId),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          backgroundImage: CachedNetworkImageProvider(comment.ownerImgUrl),
          radius: 20
        ),
      ),
      AppTheme.widthSpace10,
      Expanded(
        child: Container(
          decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(
            style: BorderStyle.solid, color: Colors.grey, width: 0.5)),
          child: Card(
            color: AppColor.getContextCardColor(context),
            elevation: 0,
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: <Widget>[
                usernameSectionWithoutAvatar(context, _.profile.id, comment,
                    role: _.userController.user?.userRole ?? UserRole.subscriber),
                AppTheme.heightSpace5,
                (comment.mediaUrl.isEmpty ||  comment.mediaUrl == _.post.mediaUrl) ? const SizedBox.shrink() :
                Column(
                  children: [
                    SizedBox(
                      height: 250, width: 250,
                      child: customCachedNetworkHeroImage(comment.mediaUrl),
                    ),
                  AppTheme.heightSpace5,
                ],),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    comment.text.isEmpty ? const SizedBox.shrink() :
                    Expanded(
                      child: (comment.text.contains("http") || comment.text.contains("https"))
                          ? Linkify(
                        onOpen: (link)  {
                          CoreUtilities.launchURL(link.url);
                        },
                        text: comment.text,
                        maxLines: 20,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16),
                        linkStyle: const TextStyle(fontSize: 16, color: AppColor.dodgetBlue),
                      ) : Text(
                        comment.text,
                        maxLines: 20,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if(_.profile.id != comment.ownerId) IconButton(
                      constraints: const BoxConstraints(),
                      icon: Icon(_.isLikedComment(comment) ? FontAwesomeIcons.solidHeart
                          :  FontAwesomeIcons.heart, size: AppTheme.postIconSize),
                      onPressed: () => _.handleLikeComment(comment),
                    ),
                  ],
                ),
                ///TODO
                //menuReply(comment),
              ],
            ),
          ),
        ),
      )
      )
    ],
  );
}

Widget usernameSectionWithoutAvatar(BuildContext context, String profileId, PostComment comment,
    {showDots = true, UserRole role = UserRole.subscriber}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GestureDetector(
                    onTap: () => profileId == comment.ownerId ? Get.toNamed(AppRouteConstants.profile)
                        : Get.toNamed(AppRouteConstants.mateDetails, arguments: comment.ownerId),
                    child: Text(comment.ownerName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                      ))
                    ,
                  ),
                  AppTheme.widthSpace5,
                  Text(AppUtilities.getTimeAgo(comment.createdTime, showShort: false),
                      style: const TextStyle(fontSize: 12, color: AppColor.white)
                  ),                  
                ],
              ),
            ],
          )
        ],
      ),
      showDots ? IconButton(
          constraints: const BoxConstraints(),
          onPressed: () => showModalBottomSheet(
              backgroundColor: AppTheme.canvasColor75(context),
              context: context,
              builder: (context) {
                return _buildCommentBottomNavMenu(context,
                    profileId == comment.ownerId, comment, role);
              }),
          icon: const Icon(FontAwesomeIcons.ellipsisVertical, size: 20)
      ) : const SizedBox.shrink(),            //moreOptions3Dots(context),
    ],
  );
}


Widget _buildCommentBottomNavMenu(BuildContext context, bool isSelf, PostComment comment, UserRole userRole) {
  List<Menu3DotsModel> listMore = [];

  if(isSelf) {
    //TODO Edit Comment
    listMore.add(Menu3DotsModel(AppTranslationConstants.removeComment, AppTranslationConstants.removeCommentMsg,
        Icons.delete, AppTranslationConstants.removeComment));
  } else {
    listMore.add(Menu3DotsModel(AppTranslationConstants.hideComment, AppTranslationConstants.hideCommentMsg,
        Icons.hide_source, AppTranslationConstants.hideComment));
    listMore.add(Menu3DotsModel(AppTranslationConstants.reportComment, AppTranslationConstants.reportCommentMsg,
        Icons.info, AppTranslationConstants.reportComment));
    listMore.add(Menu3DotsModel('${AppTranslationConstants.toBlock.tr} ${comment.ownerName}',
        AppTranslationConstants.blockProfileMsg, Icons.block, AppTranslationConstants.blockProfile));

    if(userRole != UserRole.subscriber) {
      listMore.add(Menu3DotsModel(AppTranslationConstants.removeComment, AppTranslationConstants.reportCommentMsg,
          Icons.delete, AppTranslationConstants.removeComment));
    }
  }
  return Container(
      height: isSelf ? 100 : 300,
      decoration: BoxDecoration(
        color: AppColor.main50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: ListView.builder(
          itemCount: listMore.length,
          itemBuilder: (BuildContext context, int index){
            return ListTile(
              title: Text(listMore[index].title.tr, style: const TextStyle(fontSize: 18)),
              subtitle: Text(listMore[index].subtitle.tr),
              leading: Icon(listMore[index].icons, size: 20, color: Colors.white),
              onTap: () async {
                switch (listMore[index].action) {
                  case AppTranslationConstants.editPost:
                    AppUtilities.showSnackBar(title: AppTranslationConstants.underConstruction, message: AppTranslationConstants.underConstructionMsg);
                    break;
                  case AppTranslationConstants.hideComment:
                    PostCommentsController postCommentsController = Get.find<PostCommentsController>();
                    postCommentsController.showHideCommentAlert(context, comment);
                    break;
                  case AppTranslationConstants.reportComment:
                    ReportController reportController = Get.put(ReportController());
                    reportController.showSendReportAlert(context, comment.id, referenceType: ReferenceType.comment);
                    break;
                  case AppTranslationConstants.blockProfile:
                    PostCommentsController postCommentsController = Get.find<PostCommentsController>();
                    postCommentsController.showBlockProfileAlert(context, comment.ownerId);
                    break;
                  case AppTranslationConstants.removeComment:
                    PostCommentsController postCommentsController = Get.find<PostCommentsController>();
                    postCommentsController.showRemoveCommentAlert(context, comment);
                    break;
                }
              },
            );
          })
  );
}

Widget shortFeedNewsCardItem(BuildContext context, PostCommentsController _) {
  String caption = _.post.caption;
  if(caption.contains(AppConstants.titleTextDivider)) {
    caption = caption.split(AppConstants.titleTextDivider)[1];
  }

  return Container(
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      border: Border.all(style: BorderStyle.solid, color: Colors.grey, width: 0.5),
    ),
    child: Card(
      elevation: 0,
      color: AppColor.getContextCardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: <Widget>[
            userAvatarSection(
              context, _.profile.id, _.post,
              role: _.userController.user!.userRole,
            ),
            AppTheme.heightSpace5,
            if(caption.isNotEmpty)
              Align(
                  alignment: Alignment.centerLeft,
                  child: HashtagLinkText(text: caption,)
              )

          ],
        ),
      ),
    ),
  );
}
