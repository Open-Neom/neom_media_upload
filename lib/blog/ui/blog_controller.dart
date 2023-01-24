import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/firestore/post_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/post.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';

import '../domain/use_cases/blog_entry_service.dart';

class BlogController extends GetxController implements BlogEntryService {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  Post currentBlogEntry = Post();
  int tabIndex = 0;

  final RxMap<String, Post> _blogEntries = <String, Post>{}.obs;
  Map<String, Post> get blogEntries => _blogEntries;
  set blogEntries(Map<String, Post> blogEntries) => _blogEntries.value = blogEntries;

  final RxMap<String, Post> _draftEntries = <String, Post>{}.obs;
  Map<String, Post> get draftEntries => _draftEntries;
  set draftEntries(Map<String, Post> draftEntries) => _draftEntries.value = draftEntries;

  AppProfile profile = AppProfile();
  AppProfile mate = AppProfile();
  String blogOwnerId = "";

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

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
          mate = Get.arguments[0];
          blogOwnerId = mate.id;
          await getBlogEntries();
        }
      } else {
        blogOwnerId = profile.id;
        await getBlogEntries();
      }

    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void onReady() async {

    try {

    } catch (e) {
      logger.e(e.toString());
      Get.snackbar(
          MessageTranslationConstants.spotifySynchronization.tr,
          e.toString(),
          snackPosition: SnackPosition.bottom,
      );
    }

    isLoading = false;
    update([AppPageIdConstants.blog]);
  }


  void clear() {
    blogEntries = <String, Post>{};
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
  Future<void> updateBlogEntry(String itemlistId, Post blogEntry) async {

    logger.d("Updating to $blogEntry");

    try {
      isLoading = true;
      update([AppPageIdConstants.itemlist]);

      if(newBlogEntryNameController.text.isNotEmpty || newBlogEntryTextController.text.isNotEmpty) {

        if(newBlogEntryNameController.text.isNotEmpty) {
          blogEntry.caption = newBlogEntryNameController.text;
        }

        if(newBlogEntryTextController.text.isNotEmpty) {
          blogEntry.caption = newBlogEntryTextController.text;
        }

        // if(await ItemlistFirestore().update(profile.id, itemlist)){
        //   logger.d("Itemlist $itemlistId updated");
        //   //_blogEntries[itemlist.id] = itemlist;
        //   clearNewItemlist();
        // } else {
        //   logger.i("Something happens trying to update itemlist");
        // }
      }
    } catch (e) {
      logger.e(e.toString());
    }


    isLoading = false;
    Get.back();
    update([AppPageIdConstants.blog]);
  }

  @override
  Future<void> getBlogEntries() async {
    logger.d("Getting Blog Entries Published and Drafts");
    try {

      blogEntries = await PostFirestore().getBlogEntries(profileId: blogOwnerId);
      if(blogEntries.isNotEmpty) {
        blogEntries.values.where((blogEntry) => blogEntry.isDraft)
            .forEach((draft) {
          draftEntries[draft.id] = draft;
        });

        blogEntries.removeWhere((key, blogEntry) => blogEntry.isDraft);
      }
    } catch (e) {
      logger.e(e.toString());
    }


    logger.d("Blog Entries loaded");
    update([AppPageIdConstants.blog]);
  }

}
