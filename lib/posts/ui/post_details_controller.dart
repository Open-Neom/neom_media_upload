import 'package:get/get.dart';
import 'package:neom_commons/core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_commons/core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_commons/core/data/firestore/post_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/activity_feed.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/post.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/enums/activity_feed_type.dart';
import 'package:neom_commons/core/utils/enums/push_notification_type.dart';
import 'package:neom_timeline/neom_timeline.dart';

import '../data/firestore/comment_firestore.dart';
import '../domain/use_cases/post_details_service.dart';

class PostDetailsController extends GetxController implements PostDetailsService {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  AppProfile profile = AppProfile();
  Post post = Post();
  String postId = "";

  bool showInfo = true;
  bool isLiked = false;

  final RxBool isLoading = true.obs;

  @override
  void onInit() async {
    super.onInit();
    logger.i("PostDetails Controller Init");
    profile = userController.profile;
    try {

      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        if (Get.arguments[0] is Post) {
          post = Get.arguments[0];
          postId = post.id;
        } else if (Get.arguments[0] is String) {
          postId = Get.arguments[0];
        }
      }

    } catch (e) {
      logger.e(e.toString());
    }
  }


  @override
  void onReady() async {
    super.onReady();
    if(postId.isNotEmpty) {
      await retrievePost();
    }
    isLoading.value = false;
    update([AppPageIdConstants.postDetails]);
  }

  @override
  Future<void> retrievePost() async {
    try {
      post = await PostFirestore().retrieve(postId);
      post.comments = await CommentFirestore().retrieveComments(postId: postId);
    } catch (e) {
      logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.postDetails]);
  }


  @override
  void showPostInfo(bool show){
    showInfo = show;
    update([AppPageIdConstants.postDetails]);
  }


  @override
  bool isLikedPost(Post post) {
    return post.likedProfiles.contains(profile.id);
  }

  @override
  Future<void> handleLikePost(Post post) async {
    isLiked = isLikedPost(post);

    try {
      if (await PostFirestore().handleLikePost(profile.id, post.id, isLiked)) {

        if(profile.id != post.ownerId) {
          ActivityFeed activityFeed = ActivityFeed(
              id: post.id,
              ownerId: post.ownerId,
              profileId: profile.id,
              createdTime: DateTime.now().millisecondsSinceEpoch);

          activityFeed.activityFeedType = ActivityFeedType.like;
          activityFeed.profileName = profile.name;
          activityFeed.profileImgUrl = profile.photoUrl;
          activityFeed.mediaUrl = post.mediaUrl;
          activityFeed.activityReferenceId = post.id;

          isLiked ? await ActivityFeedFirestore()
              .removeActivityById(activityFeed.ownerId, activityFeed.id)
              : ActivityFeedFirestore().insert(activityFeed);

          if(!isLiked) {
            FirebaseMessagingCalls.sendPrivatePushNotification(
                toProfileId: post.ownerId,
                fromProfile: profile,
                notificationType: PushNotificationType.like,
                referenceId: post.id,
                imgUrl: post.mediaUrl
            );

            FirebaseMessagingCalls.sendGlobalPushNotification(
                fromProfile: profile,
                toProfile: await ProfileFirestore().retrieve(post.ownerId),
                notificationType: PushNotificationType.like,
                referenceId: post.id,
                imgUrl: post.mediaUrl
            );
          }
        }

        isLiked ? post.likedProfiles.remove(profile.id)
            : post.likedProfiles.add(profile.id);

      }

      Get.find<TimelineController>().handleLikeOnPost(post);
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.postDetails, AppPageIdConstants.blogEntry]);
  }

  @override
  bool verifyIfCommented(List<String> postCommentIds, List<String> profileCommentIds) {

    if(profileCommentIds.isNotEmpty) {
      for(String postCommentId in postCommentIds) {
        if(profileCommentIds.contains(postCommentId)){
          return true;
        }
      }
    }

    return false;
  }


  @override
  void setCommentToPost(String commentId) {
    if(!post.commentIds.contains(commentId)) {
      post.commentIds.add(commentId);
    }

    update([AppPageIdConstants.postDetails]);
  }

}
