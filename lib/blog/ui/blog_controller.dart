import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/firestore/post_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/post.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';

import '../domain/use_cases/blog_entry_service.dart';

class BlogController extends GetxController implements BlogEntryService {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  AppProfile profile = AppProfile();
  AppProfile mate = AppProfile();
  String blogOwnerId = "";

  Post currentBlogEntry = Post();
  int tabIndex = 0;

  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;
  final RxMap<String, Post> blogEntries = <String, Post>{}.obs;
  final RxMap<String, Post> draftEntries = <String, Post>{}.obs;

  TextEditingController newBlogEntryNameController = TextEditingController();
  TextEditingController newBlogEntryTextController = TextEditingController();

  @override
  void onInit() async {
    super.onInit();
    logger.d("");
    try {
      profile = userController.profile;

      if(Get.arguments != null) {
        List<dynamic> arguments = Get.arguments;
        if(arguments.isNotEmpty) {
          if(Get.arguments[0] is AppProfile) {
            mate = Get.arguments[0];
            blogOwnerId = mate.id;
          } else {
            blogOwnerId = Get.arguments[0];
            mate = await ProfileFirestore().retrieve(blogOwnerId);
          }
        }
      } else {
        blogOwnerId = profile.id;
      }
      await getBlogEntries();
    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void onReady() async {

    try {

    } catch (e) {
      logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.blog]);
  }


  void clear() {
    blogEntries.value = <String, Post>{};
    currentBlogEntry = Post();
  }


  void clearNewItemlist() {
    newBlogEntryNameController.clear();
    newBlogEntryTextController.clear();
  }


  @override
  Future<void> gotoNewBlogEntry() async {
    logger.d("Start ${newBlogEntryNameController.text} and ${newBlogEntryTextController.text}");

    try {
      Get.toNamed(AppRouteConstants.blogEditor);
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.blog]);
  }

  @override
  Future<void> updateBlogEntry(String itemlistId, Post postBlogEntry) async {

    logger.d("Updating to $postBlogEntry");

    try {
      isLoading.value = true;
      update([AppPageIdConstants.itemlist]);

      if(newBlogEntryNameController.text.isNotEmpty || newBlogEntryTextController.text.isNotEmpty) {

        if(newBlogEntryNameController.text.isNotEmpty) {
          postBlogEntry.caption = newBlogEntryNameController.text;
        }

        if(newBlogEntryTextController.text.isNotEmpty) {
          postBlogEntry.caption = newBlogEntryTextController.text;
        }

      }
    } catch (e) {
      logger.e(e.toString());
    }


    isLoading.value = false;
    Get.back();
    update([AppPageIdConstants.blog]);
  }

  @override
  Future<void> getBlogEntries() async {
    logger.d("Getting Blog Entries Published and Drafts");
    try {

      blogEntries.value = await PostFirestore().getBlogEntries(profileId: blogOwnerId);
      if(blogEntries.isNotEmpty) {
        blogEntries.values.where((entry) => entry.isDraft)
            .forEach((draft) {
          draftEntries[draft.id] = draft;
        });

        blogEntries.removeWhere((key, entry) => entry.isDraft);
      }
    } catch (e) {
      logger.e(e.toString());
    }


    logger.d("Blog Entries loaded");
    update([AppPageIdConstants.blog]);
  }

}
