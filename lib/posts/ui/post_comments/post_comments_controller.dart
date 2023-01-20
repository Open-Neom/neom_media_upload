import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:neom_commons/core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_commons/core/data/firestore/post_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/post.dart';
import 'package:neom_commons/core/domain/model/post_comment.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/enums/activity_feed_type.dart';
import 'package:neom_commons/core/utils/enums/app_file_from.dart';
import 'package:neom_commons/core/utils/enums/app_media_type.dart';
import 'package:neom_commons/core/utils/enums/post_type.dart';
import 'package:neom_commons/core/utils/enums/push_notification_type.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';
import 'package:neom_commons/core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_commons/core/domain/model/activity_feed.dart';
import '../../data/firestore/comment_firestore.dart';
import '../../domain/use_cases/post_comments_service.dart';
import '../add/post_upload_controller.dart';
import '../post_details_controller.dart';


class PostCommentsController extends GetxController implements PostCommentsService {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();
  final timelineController = Get.find<TimelineController>();
  final postUploadController = Get.put(PostUploadController());

  PostFirestore postFirestore = PostFirestore();
  CommentFirestore commentFirestore = CommentFirestore();

  final ScrollController scrollController = ScrollController();

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  TextEditingController commentController = TextEditingController();
  bool isUploading = false;

  final PickedFile _imageFile = PickedFile("");
  PickedFile get imageFile => _imageFile;

  AppProfile profile = AppProfile();
  Post post = Post();
  RxList<PostComment> comments = <PostComment>[].obs;


  Map likes = {};
  int likesCount = 0;
  bool isLiked = false;
  bool showHeart = false;

  @override
  void onInit() async {
    super.onInit();
    logger.d("Post Controller Init");

    profile = userController.profile;

    //TODO VERIFY THIS
    try {
      post = Get.arguments ?? Post();
    } catch (e) {
      logger.e(e.toString());
    }

  }


  @override
  void onReady() async {
    super.onReady();
    logger.d("Post Comments Controller Ready");
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
    update([AppPageIdConstants.postComments, AppPageIdConstants.postDetails]);
  }


  @override
  Future<void> addComment() async {
    logger.d("Adding comment to Post and Comment Collections");
    try {
      PostComment newComment = PostComment(
        postOwnerId: post.ownerId,
        text: commentController.text,
        postId: post.id,
        profileId: profile.id,
        profileImgUrl: profile.photoUrl,
        profileName: profile.name,
        createdTime: DateTime
            .now().millisecondsSinceEpoch,
        mediaUrl: post.mediaUrl,
      );

      if(commentController.text.isNotEmpty || postUploadController.imageFile.path.isNotEmpty) {
        isUploading = true;
        isButtonDisabled = true;
        update([AppPageIdConstants.postComments]);



        if (postUploadController.imageFile.path.isNotEmpty) {
          newComment.mediaUrl =
          await postUploadController.handleUploadImage(UploadImageType.comment);
          newComment.type = AppMediaType.image;
        }

        newComment.id = await CommentFirestore().insert(newComment);
        if(newComment.id.isNotEmpty) {
          userController.profile.comments = [];
          userController.profile.comments!.add(newComment.id);
          timelineController.addCommentToPost(post.id, newComment);

          if (profile.id != post.ownerId) {
            sendPushNotificationToFcm(
                toProfileId: post.ownerId,
                fromProfile: profile,
                notificationType: PushNotificationType.comment,
                message: newComment.text,
                referenceId: post.id,
                imgUrl: post.mediaUrl
            );
          }
          post.commentIds.add(newComment.id);
        }

        comments.add(newComment);
        clearComment();
        clearImage();
      } else {
        logger.d("Comment and Comment Image are empty");
      }

      Get.find<PostDetailsController>().setCommentToPost(newComment.id);
      if(post.type == PostType.blogEntry) {
        Get.find<BlogEditorController>().setCommentToBlogEntry(newComment.id);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    isUploading = false;
    isButtonDisabled = false;
    update([AppPageIdConstants.postComments, AppPageIdConstants.timeline,
      AppPageIdConstants.postDetails, AppPageIdConstants.blogEntry,
      AppPageIdConstants.blogEditor]);
  }


  @override
  Future<void> handleImage(AppFileFrom appFileFrom) async {
    await postUploadController.handleImage(appFileFrom, isProfilePicture: true);
    update([AppPageIdConstants.postComments]);
  }


  @override
  void clearComment()  {
    commentController.clear();
    update([AppPageIdConstants.postComments]);
  }


  @override
  void clearImage()  {
    postUploadController.clearImage();
    update([AppPageIdConstants.postComments]);
  }


  @override
  bool isLikedComment(PostComment comment) {
    return comment.likedProfiles.contains(profile.id);
  }


  @override
  Future<void> handleLikeComment(PostComment comment) async {

    isLiked = isLikedComment(comment);


    if (await commentFirestore.handleLikeComment(profile.id, comment.id, isLiked)) {

      if(profile.id != comment.profileId) {

        if(isLiked) {
          ActivityFeedFirestore()
              .removeByReferenceActivity(comment.postOwnerId, ActivityFeedType.commentLike,
              activityReferenceId: post.id);
        } else {
          ActivityFeed activityFeed = ActivityFeed();

          activityFeed.ownerId =  comment.profileId;
          activityFeed.profileId = profile.id;
          activityFeed.createdTime = DateTime.now().millisecondsSinceEpoch;
          activityFeed.activityReferenceId = post.id;
          activityFeed.activityFeedType = ActivityFeedType.commentLike;
          activityFeed.profileName = profile.name;
          activityFeed.profileImgUrl = profile.photoUrl;
          activityFeed.mediaUrl = comment.mediaUrl.isNotEmpty ? comment.mediaUrl : post.mediaUrl;
          await ActivityFeedFirestore().insert(activityFeed);
        }
      }

      if(await CommentFirestore().handleLikeComment(profile.id, comment.id, isLiked)) {
        isLiked ? comment.likedProfiles.remove(profile.id)
            : comment.likedProfiles.add(profile.id);
      }

    }

    update([AppPageIdConstants.postComments]);
  }


  @override
  Future<void> hideComment(PostComment comment) async {

    try {
      if(await ProfileFirestore().hideComment(profile.id, comment.id)) {
        comments.remove(comment);
      } else {
        logger.i("Something happened while hidding post");
      }

    } catch (e) {
      logger.e(e.toString());
    }

    Get.back();
    Get.back();
    update([AppPageIdConstants.postComments]);
  }


  @override
  Future<void> removeComment(PostComment comment) async {

    try {
      if(await CommentFirestore().remove(comment)) {
        timelineController.removeCommentToPost(post.id, comment);
        comments.remove(comment);
      } else {
        logger.i("Something happened while removing post");
      }

    } catch (e) {
      logger.e(e.toString());
    }

    Get.back();
    Get.back();
    update([AppPageIdConstants.postComments]);

  }


}
