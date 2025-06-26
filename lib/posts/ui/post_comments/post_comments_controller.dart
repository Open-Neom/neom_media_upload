import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/utils/app_alerts.dart';
import 'package:neom_commons/commons/utils/app_utilities.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/core/app_config.dart';
import 'package:neom_core/core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_core/core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_core/core/data/firestore/post_firestore.dart';
import 'package:neom_core/core/data/firestore/profile_firestore.dart';
import 'package:neom_core/core/data/implementations/mate_controller.dart';
import 'package:neom_core/core/data/implementations/user_controller.dart';
import 'package:neom_core/core/domain/model/activity_feed.dart';
import 'package:neom_core/core/domain/model/app_profile.dart';
import 'package:neom_core/core/domain/model/post.dart';
import 'package:neom_core/core/domain/model/post_comment.dart';
import 'package:neom_core/core/utils/enums/activity_feed_type.dart';
import 'package:neom_core/core/utils/enums/app_file_from.dart';
import 'package:neom_core/core/utils/enums/app_media_type.dart';
import 'package:neom_core/core/utils/enums/post_type.dart';
import 'package:neom_core/core/utils/enums/push_notification_type.dart';
import 'package:neom_core/core/utils/enums/upload_image_type.dart';
import 'package:neom_timeline/neom_timeline.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../../blog/ui/blog_editor_controller.dart';
import '../../data/firestore/comment_firestore.dart';
import '../../domain/use_cases/post_comments_service.dart';
import '../post_details_controller.dart';
import '../upload/post_upload_controller.dart';


class PostCommentsController extends GetxController implements PostCommentsService {

  final userController = Get.find<UserController>();
  final timelineController = Get.find<TimelineController>();
  final postUploadController = Get.put(PostUploadController());

  PostFirestore postFirestore = PostFirestore();
  CommentFirestore commentFirestore = CommentFirestore();

  AppProfile profile = AppProfile();
  Post post = Post();

  final ScrollController scrollController = ScrollController();
  TextEditingController commentController = TextEditingController();

  RxBool isLoading = true.obs;
  RxBool isButtonDisabled = false.obs;
  RxBool isUploading = false.obs;
  RxList<PostComment> comments = <PostComment>[].obs;
  RxBool sendingMessage = false.obs;
  PickedFile imageFile = PickedFile("");

  Map likes = {};
  int likesCount = 0;
  bool isLiked = false;
  bool showHeart = false;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.d("Post Controller Init");

    profile = userController.profile;

    //TODO VERIFY THIS
    try {
      post = Get.arguments ?? Post();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    AppConfig.logger.d("Post Comments Controller Ready");
    post = await PostFirestore().retrieve(post.id);

    if(post.comments.isNotEmpty) {
      for (var comment in post.comments) {
        if((profile.hiddenComments?.contains(comment.id) ?? false) == false) {
          comments.add(comment);
        }
      }
    } else if (post.commentIds.isNotEmpty) {
      post.comments = await commentFirestore.retrieveComments(postId: post.id);
      comments.value = post.comments;
    }

    comments.sort((a, b) => a.createdTime.compareTo(b.createdTime));

    isLoading.value = false;
    update([AppPageIdConstants.postComments, AppPageIdConstants.postDetails]);
  }

  @override
  Future<void> addComment() async {
    AppConfig.logger.d("Adding comment to Post and Comment Collections");
    sendingMessage.value = true;

    try {
      PostComment newComment = PostComment(
        postOwnerId: post.ownerId,
        text: commentController.text,
        postId: post.id,
        ownerId: profile.id,
        ownerImgUrl: profile.photoUrl,
        ownerName: profile.name,
        createdTime: DateTime
            .now().millisecondsSinceEpoch,
        mediaUrl: post.mediaUrl,
      );

      if(commentController.text.isNotEmpty || postUploadController.mediaFile.value.path.isNotEmpty) {
        isUploading.value = true;
        isButtonDisabled.value = true;
        update([AppPageIdConstants.postComments]);



        if (postUploadController.mediaFile.value.path.isNotEmpty) {
          newComment.mediaUrl =
          await postUploadController.handleUploadImage(UploadImageType.comment);
          newComment.type = AppMediaType.image;
        }

        addCommentToList(newComment);

        newComment.id = await CommentFirestore().insert(newComment);
        if(newComment.id.isNotEmpty) {
          userController.profile.comments = [];
          userController.profile.comments!.add(newComment.id);
          timelineController.addCommentToPost(post.id, newComment);

          if (profile.id != post.ownerId) {
            FirebaseMessagingCalls.sendPrivatePushNotification(
                toProfileId: post.ownerId,
                fromProfile: profile,
                notificationType: PushNotificationType.comment,
                title: AppTranslationConstants.commentedYourPost,
                message: newComment.text,
                referenceId: post.id,
                imgUrl: post.mediaUrl
            );

            AppProfile postOwner = await ProfileFirestore().retrieve(post.ownerId);
            FirebaseMessagingCalls.sendPublicPushNotification(
                fromProfile: profile,
                toProfileId: postOwner.id,
                notificationType: PushNotificationType.comment,
                title: "${AppTranslationConstants.commentedThePostOf.tr} ${postOwner.name}",
                referenceId: post.id,
                message: newComment.text,
                imgUrl: post.mediaUrl
            );
          }
          post.commentIds.add(newComment.id);
        }


      } else {
        AppConfig.logger.d("Comment and Comment Image are empty");
      }

      PostDetailsController postDetailsController;
      if (Get.isRegistered<PostDetailsController>()) {
        postDetailsController = Get.find<PostDetailsController>();
      } else {
        postDetailsController = PostDetailsController();
        Get.put(postDetailsController);
      }
      postDetailsController.setCommentToPost(newComment.id);

      if(post.type == PostType.blogEntry) {
        Get.find<BlogEditorController>().setCommentToBlogEntry(newComment.id);
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    clearComment();
    isUploading.value = false;
    isButtonDisabled.value = false;
    sendingMessage.value = false;

    update([AppPageIdConstants.postComments, AppPageIdConstants.timeline,
      AppPageIdConstants.postDetails, AppPageIdConstants.blogEntry,
      AppPageIdConstants.blogEditor]);
  }

  @override
  Future<void> handleImage(AppFileFrom appFileFrom) async {
    await postUploadController.handleImage(appFileFrom: appFileFrom, imageType: UploadImageType.profile);
    update([AppPageIdConstants.postComments]);
  }

  @override
  void addCommentToList(PostComment newComment)  {
    comments.add(newComment);
    clearComment();
    clearImage();
    update([AppPageIdConstants.postComments, AppPageIdConstants.timeline,
      AppPageIdConstants.postDetails, AppPageIdConstants.blogEntry,
      AppPageIdConstants.blogEditor]);
  }

  @override
  void clearComment()  {
    commentController.clear();
    update([AppPageIdConstants.postComments]);
  }

  @override
  void clearImage()  {
    postUploadController.clearMedia();
    update([AppPageIdConstants.postComments]);
  }

  @override
  bool isLikedComment(PostComment comment) {
    return comment.likedProfiles.contains(profile.id);
  }

  @override
  Future<void> handleLikeComment(PostComment comment) async {
    AppConfig.logger.d("handleLikeComment");
    try {
      isLiked = isLikedComment(comment);
      isLiked ? comment.likedProfiles.remove(profile.id)
          : comment.likedProfiles.add(profile.id);
      update([AppPageIdConstants.postComments]);

      if (await commentFirestore.handleLikeComment(profile.id, comment.id, isLiked)) {

        if(profile.id != comment.ownerId) {
          if(isLiked) {
            ActivityFeedFirestore().removeByReferenceActivity(comment.postOwnerId,
                ActivityFeedType.commentLike, activityReferenceId: post.id);
          } else {
            ActivityFeed activityFeed = ActivityFeed.fromComment(comment: comment, type: ActivityFeedType.commentLike,
              fromProfile: profile, mediaUrl: comment.mediaUrl.isNotEmpty ? comment.mediaUrl : post.mediaUrl);
            ActivityFeedFirestore().insert(activityFeed);
          }
        }
      }
      
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.postComments]);
  }

  @override
  Future<void> hideComment(PostComment comment) async {

    try {
      if(await ProfileFirestore().hideComment(profile.id, comment.id)) {
        comments.remove(comment);
      } else {
        AppConfig.logger.i("Something happened while hidding comment");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.postComments]);
  }

  @override
  Future<void> showHideCommentAlert(BuildContext context, PostComment comment) async {
    Alert(
        context: context,
        style: AlertStyle(
          backgroundColor: AppColor.main50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        title: AppTranslationConstants.hideComment.tr,
        content: Column(
          children: [
            Text(AppTranslationConstants.hideCommentMsg2.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ],),
        buttons: [
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslationConstants.goBack.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () async {
              await hideComment(comment);
              Navigator.pop(context);
              Navigator.pop(context);
              AppUtilities.showSnackBar(message: AppTranslationConstants.hiddenCommentMsg.tr);
            },
            child: Text(AppTranslationConstants.toHide.tr,
              style: const TextStyle(fontSize: 15),
            ),
          )
        ]
    ).show();
  }

  @override
  Future<void> showRemoveCommentAlert(BuildContext context, PostComment comment) async {
    Alert(
        context: context,
        style: AlertStyle(
          backgroundColor: AppColor.main50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        title: AppTranslationConstants.removeThisComment.tr,
        content: Column(
          children: [
            Text(AppTranslationConstants.removeCommentMsg.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
        buttons: [
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslationConstants.goBack.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () async {
              await removeComment(comment);
              Navigator.pop(context);
              Navigator.pop(context);
              AppUtilities.showSnackBar(message: AppTranslationConstants.removedCommentMsg);
            },
            child: Text(AppTranslationConstants.toRemove.tr,
              style: const TextStyle(fontSize: 15),
            ),
          )
        ]
    ).show();
  }

  @override
  Future<void> removeComment(PostComment comment) async {

    try {
      if(await CommentFirestore().remove(comment)) {
        timelineController.removeCommentToPost(post.id, comment);
        comments.remove(comment);
      } else {
        AppConfig.logger.w("Something happened while removing post");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.timeline]);
  }
  @override
  Future<void> showBlockProfileAlert(BuildContext context, String commentOwnerId) async {
    MateController itemmateController = Get.put(MateController());
    AppAlerts.showBlockProfileAlert(itemmateController, context, commentOwnerId);
    userController.profile.blockTo!.add(commentOwnerId);
    comments.removeWhere((element) => element.ownerId == commentOwnerId);
    update([AppPageIdConstants.timeline]);
  }

}
