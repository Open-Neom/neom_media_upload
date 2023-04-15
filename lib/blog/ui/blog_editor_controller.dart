import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hashtagable/functions.dart';
import 'package:neom_commons/core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_commons/core/data/firestore/hashtag_firestore.dart';
import 'package:neom_commons/core/data/firestore/post_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/implementations/geolocator_controller.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/hashtag.dart';
import 'package:neom_commons/core/domain/model/post.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/post_type.dart';
import 'package:neom_commons/core/utils/enums/push_notification_type.dart';
import 'package:neom_timeline/neom_timeline.dart';

import '../../posts/ui/post_details_controller.dart';
import '../domain/use_cases/blog_editor_service.dart';
import 'blog_controller.dart';


class BlogEditorController extends GetxController implements BlogEditorService {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();
  final blogController = Get.find<BlogController>();
  final postDetailController = Get.put(PostDetailsController());

  final Rx<AppProfile> _profile = AppProfile().obs;
  AppProfile get profile => _profile.value;
  set profile(AppProfile profile) => _profile.value = profile;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  TextEditingController entryTitleController = TextEditingController();
  String lastEntryTitle = "";
  TextEditingController entryTextController = TextEditingController();
  String lastEntryText = "";

  final RxMap<String, Post> _blogEntries = <String, Post>{}.obs;
  Map<String, Post> get blogEntries => _blogEntries;
  set blogEntries(Map<String, Post> blogEntries) => _blogEntries.value = blogEntries;

  final RxInt _wordQty = 0.obs;
  int get wordQty => _wordQty.value;
  set wordQty(int wordQty) => _wordQty.value = wordQty;

  final Rx<Post> _blogEntry = Post().obs;
  Post get blogEntry => _blogEntry.value;
  set blogEntry(Post blogEntry) => _blogEntry.value = blogEntry;


  final RxBool _isLiked = false.obs;
  bool get isLiked => _isLiked.value;
  set isLiked(bool isLiked) => _isLiked.value = isLiked;

  String thumbnailUrl = "";

  @override
  void onInit() async {
    super.onInit();
    logger.d("Blog Entry Editor Controller");

    try {

      profile = userController.profile;
      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        blogEntry = Get.arguments[0];
      }

      if(blogEntry.caption.isNotEmpty) {
        List<String> blogEntryCaptionSplitted = blogEntry.caption.split(AppConstants.titleTextDivider);
        if(blogEntryCaptionSplitted.isNotEmpty) {
          if(blogEntryCaptionSplitted.length > 1) {
            entryTitleController.text = blogEntryCaptionSplitted[0];
            entryTextController.text = blogEntryCaptionSplitted[1];
          } else {
            entryTextController.text = blogEntryCaptionSplitted[0];
          }

          wordQty = entryTextController.text.split(' ').length;
        }

      } else {
        blogEntry.isDraft = true;
        blogEntry.ownerId = profile.id;
      }

    } catch (e) {
      logger.e(e);
    }
  }

  @override
  void onReady() async {
    super.onReady();
    logger.d("Create Blog Entry Controller Ready");
    try {
      postDetailController.profile = profile;
      postDetailController.post = blogEntry;
      isLiked = postDetailController.isLikedPost(blogEntry);
      isLoading = false;
    } catch (e) {

      logger.e(e.toString());
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
      wordQty = entryTextSplitted.length;
    }

    logger.d("Blog entry has $wordQty words");


    update([AppPageIdConstants.blogEditor]);
  }

  @override
  Future<void> saveBlogEntryDraft() async {
    logger.d("Saving Blog Entry Draft");

    try {

      String blogEntryCaption = entryTitleController.text + AppConstants.titleTextDivider + entryTextController.text;
      blogEntry = Post(
          id: blogEntry.id,
          caption: blogEntryCaption,
          type: PostType.blogEntry,
          profileName: profile.name,
          profileImgUrl: profile.photoUrl,
          ownerId: profile.id,
          thumbnailUrl: thumbnailUrl,
          position: profile.position,
          location:  await GeoLocatorController().getAddressSimple(profile.position!),
          isCommentEnabled: true,
          createdTime: DateTime.now().millisecondsSinceEpoch,
          isDraft: true
      );

      if(blogEntry.id.isEmpty) {
        blogEntry.id = await PostFirestore().insert(blogEntry);
        if(blogEntry.id.isNotEmpty && !profile.blogEntries!.contains(blogEntry.id)) {
          if(await ProfileFirestore().addBlogEntry(blogEntry.ownerId, blogEntry.id)) {
            profile.blogEntries!.add(blogEntry.id);
          }
        }
      } else {
        PostFirestore().update(blogEntry);
      }

      blogController.draftEntries[blogEntry.id] = blogEntry;
      logger.d("blogEntry ${blogEntry.id} was successfully updated");
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.blog, AppPageIdConstants.blogEditor]);
  }

  Future<void> publishBlogEntry() async {
    logger.d("PUblishing Blog Entry");

    isButtonDisabled = true;
    isLoading = true;
    update([AppPageIdConstants.blogEditor]);
    try {
      List<String> postHashtags = [];
      extractHashTags(entryTitleController.text).forEach((element) {
        postHashtags.add(element.substring(1));
      });

      String blogEntryCaption = entryTitleController.text + AppConstants.titleTextDivider + entryTextController.text;
      blogEntry = Post(
          id: blogEntry.id,
          caption: blogEntryCaption,
          hashtags: postHashtags,
          type: PostType.blogEntry,
          profileName: profile.name,
          profileImgUrl: profile.photoUrl,
          ownerId: profile.id,
          thumbnailUrl: thumbnailUrl,
          position: profile.position,
          location:  await GeoLocatorController().getAddressSimple(profile.position!),
          isCommentEnabled: true,
          createdTime: DateTime.now().millisecondsSinceEpoch,
          isDraft: false
      );

      if(await PostFirestore().update(blogEntry)) {
        if(blogEntry.hashtags.isNotEmpty) {
          for (var hashtagId in blogEntry.hashtags) {
            Hashtag hashtag = Hashtag(id: hashtagId, postIds: [blogEntry.id] , createdTime: DateTime.now().millisecondsSinceEpoch);
            if(await HashtagFirestore().exists(hashtagId)) {
              await HashtagFirestore().addPost(hashtagId, blogEntry.id);
            } else {
              await HashtagFirestore().insert(hashtag);
            }
          }
        }
      }

      await Get.find<TimelineController>().getTimeline();

      FirebaseMessagingCalls.sendGlobalPushNotification(
        fromProfile: profile,
        notificationType: PushNotificationType.blog,
        referenceId: blogEntry.ownerId,
      );

    } catch (e) {
      logger.e(e.toString());
    }

    isButtonDisabled = false;
    isLoading = false;
    update([AppPageIdConstants.blogEditor]);
    Get.offAllNamed(AppRouteConstants.home);
  }

  @override
  Future<void> handleLikePost() async {
    logger.i("isLiked is $isLiked and # de likes: ${blogEntry.likedProfiles}");
    try {
      await postDetailController.handleLikePost(blogEntry);
      isLiked = postDetailController.isLikedPost(blogEntry);
    } catch (e) {
      logger.e(e.toString());
    }
    logger.i("isLiked is $isLiked and # de likes: ${blogEntry.likedProfiles}");
    update([AppPageIdConstants.blogEntry, AppPageIdConstants.blogEditor, AppPageIdConstants.blog]);
  }

  @override
  void setCommentToBlogEntry(String commentId) {
    if(!blogEntry.commentIds.contains(commentId)) {
      blogEntry.commentIds.add(commentId);
    }

    update([AppPageIdConstants.blogEntry, AppPageIdConstants.blogEditor, AppPageIdConstants.blog]);
  }

}
