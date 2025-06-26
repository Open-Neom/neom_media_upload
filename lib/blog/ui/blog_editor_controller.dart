import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hashtagable_v3/functions.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/core/app_config.dart';
import 'package:neom_core/core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_core/core/data/firestore/hashtag_firestore.dart';
import 'package:neom_core/core/data/firestore/post_firestore.dart';
import 'package:neom_core/core/data/firestore/profile_firestore.dart';
import 'package:neom_core/core/data/implementations/geolocator_controller.dart';
import 'package:neom_core/core/data/implementations/user_controller.dart';
import 'package:neom_core/core/domain/model/app_profile.dart';
import 'package:neom_core/core/domain/model/hashtag.dart';
import 'package:neom_core/core/domain/model/post.dart';
import 'package:neom_core/core/utils/constants/app_route_constants.dart';
import 'package:neom_core/core/utils/constants/core_constants.dart';
import 'package:neom_core/core/utils/enums/post_type.dart';
import 'package:neom_core/core/utils/enums/push_notification_type.dart';
import 'package:neom_timeline/neom_timeline.dart';

import '../../posts/ui/post_details_controller.dart';
import '../domain/use_cases/blog_editor_service.dart';
import 'blog_controller.dart';


class BlogEditorController extends GetxController implements BlogEditorService {
  
  final userController = Get.find<UserController>();
  final blogController = Get.find<BlogController>();
  final postDetailController = Get.put(PostDetailsController());

  final Rx<AppProfile> profile = AppProfile().obs;
  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;
  final RxInt wordQty = 0.obs;
  final Rx<Post> blogEntry = Post().obs;
  final RxBool isLiked = false.obs;

  TextEditingController entryTitleController = TextEditingController();
  String lastEntryTitle = "";
  TextEditingController entryTextController = TextEditingController();
  String lastEntryText = "";
  String thumbnailUrl = "";

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.d("Blog Entry Editor Controller");

    try {

      profile.value = userController.profile;
      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        blogEntry.value = Get.arguments[0];
      }

      if(blogEntry.value.caption.isNotEmpty) {
        List<String> blogEntryCaptionSplitted = blogEntry.value.caption.split(CoreConstants.titleTextDivider);
        if(blogEntryCaptionSplitted.isNotEmpty) {
          if(blogEntryCaptionSplitted.length > 1) {
            entryTitleController.text = blogEntryCaptionSplitted[0];
            entryTextController.text = blogEntryCaptionSplitted[1];
          } else {
            entryTextController.text = blogEntryCaptionSplitted[0];
          }

          wordQty.value = entryTextController.text.split(' ').length;
        }

      } else {
        blogEntry.value.isDraft = true;
        blogEntry.value.ownerId = profile.value.id;
      }

    } catch (e) {
      AppConfig.logger.e(e);
    }
  }

  @override
  void onReady() async {
    super.onReady();
    AppConfig.logger.d("Create Blog Entry Controller Ready");
    try {
      postDetailController.profile = profile.value;
      postDetailController.post = blogEntry.value;
      isLiked.value = postDetailController.isLikedPost(blogEntry.value);
      isLoading.value = false;
    } catch (e) {

      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.blogEditor]);
  }

  @override
  void dispose() {
    entryTitleController.dispose();
    super.dispose();
  }

  void saveDraft(String entryText, {bool isTitle = false}) {

    List<String> entryTextSplitted = entryText.split(' ');
    entryTextSplitted.removeWhere((element) => element == "");

    if(lastEntryText.length < entryText.length && entryText.endsWith(" ")
      || lastEntryTitle.length < entryText.length && entryText.endsWith(" ")
    ) {
      saveBlogEntryDraft();
    }

    if(isTitle) {
      lastEntryTitle = entryText;
    } else {
      lastEntryText = entryText;
      wordQty.value = entryTextSplitted.length;
    }

    AppConfig.logger.d("Blog entry has $wordQty words");


    update([AppPageIdConstants.blogEditor]);
  }

  @override
  Future<void> saveBlogEntryDraft() async {
    AppConfig.logger.d("Saving Blog Entry Draft");

    try {

      String blogEntryCaption = entryTitleController.text + CoreConstants.titleTextDivider + entryTextController.text;
      blogEntry.value = Post(
        id: blogEntry.value.id,
        caption: blogEntryCaption,
        type: PostType.blogEntry,
        profileName: profile.value.name,
        profileImgUrl: profile.value.photoUrl,
        ownerId: profile.value.id,
        thumbnailUrl: thumbnailUrl,
        position: profile.value.position,
        location:  await GeoLocatorController().getAddressSimple(profile.value.position!),
        isCommentEnabled: true,
        createdTime: DateTime.now().millisecondsSinceEpoch,
        isDraft: true,
        verificationLevel: profile.value.verificationLevel,
        lastInteraction: DateTime.now().millisecondsSinceEpoch,
      );

      if(blogEntry.value.id.isEmpty) {
        blogEntry.value.id = await PostFirestore().insert(blogEntry.value);
        if(blogEntry.value.id.isNotEmpty && !profile.value.blogEntries!.contains(blogEntry.value.id)) {
          if(await ProfileFirestore().addBlogEntry(blogEntry.value.ownerId, blogEntry.value.id)) {
            profile.value.blogEntries!.add(blogEntry.value.id);
          }
        }
      } else {
        PostFirestore().update(blogEntry.value);
      }

      blogController.draftEntries[blogEntry.value.id] = blogEntry.value;
      AppConfig.logger.d("blogEntry ${blogEntry.value.id} was successfully updated");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.blog, AppPageIdConstants.blogEditor]);
  }

  Future<void> publishBlogEntry() async {
    AppConfig.logger.d("PUblishing Blog Entry");

    isButtonDisabled.value = true;
    isLoading.value = true;
    update([AppPageIdConstants.blogEditor]);
    try {
      List<String> postHashtags = [];
      extractHashTags(entryTitleController.text).forEach((element) {
        postHashtags.add(element.substring(1));
      });

      String blogEntryCaption = entryTitleController.text + CoreConstants.titleTextDivider + entryTextController.text;
      blogEntry.value = Post(
        id: blogEntry.value.id,
        caption: blogEntryCaption,
        hashtags: postHashtags,
        type: PostType.blogEntry,
        profileName: profile.value.name,
        profileImgUrl: profile.value.photoUrl,
        ownerId: profile.value.id,
        thumbnailUrl: thumbnailUrl,
        position: profile.value.position,
        location:  await GeoLocatorController().getAddressSimple(profile.value.position!),
        isCommentEnabled: true,
        createdTime: DateTime.now().millisecondsSinceEpoch,
        isDraft: false,
        lastInteraction: DateTime.now().millisecondsSinceEpoch,
      );

      if(await PostFirestore().update(blogEntry.value)) {
        if(blogEntry.value.hashtags.isNotEmpty) {
          for (var hashtagId in blogEntry.value.hashtags) {
            Hashtag hashtag = Hashtag(id: hashtagId, postIds: [blogEntry.value.id] , createdTime: DateTime.now().millisecondsSinceEpoch);
            if(await HashtagFirestore().exists(hashtagId)) {
              await HashtagFirestore().addPost(hashtagId, blogEntry.value.id);
            } else {
              await HashtagFirestore().insert(hashtag);
            }
          }
        }
      }

      await Get.find<TimelineController>().getTimeline();

      FirebaseMessagingCalls.sendPublicPushNotification(
        fromProfile: profile.value,
        notificationType: PushNotificationType.blog,
        title: AppTranslationConstants.hasPostedInBlog,
        toProfileId: '',
        referenceId: blogEntry.value.ownerId,
      );

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isButtonDisabled.value = false;
    isLoading.value = false;
    update([AppPageIdConstants.blogEditor]);
    Get.offAllNamed(AppRouteConstants.home);
  }

  @override
  Future<void> handleLikePost() async {
    AppConfig.logger.i("isLiked is $isLiked and # de likes: ${blogEntry.value.likedProfiles}");
    try {
      await postDetailController.handleLikePost(blogEntry.value);
      isLiked.value = postDetailController.isLikedPost(blogEntry.value);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    AppConfig.logger.i("isLiked is $isLiked and # de likes: ${blogEntry.value.likedProfiles}");
    update([AppPageIdConstants.blogEntry, AppPageIdConstants.blogEditor, AppPageIdConstants.blog]);
  }

  @override
  void setCommentToBlogEntry(String commentId) {
    if(!blogEntry.value.commentIds.contains(commentId)) {
      blogEntry.value.commentIds.add(commentId);
    }

    update([AppPageIdConstants.blogEntry, AppPageIdConstants.blogEditor, AppPageIdConstants.blog]);
  }

}
