import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'blog_controller.dart';
import 'widgets/blog_widgets.dart';

class BlogPage extends StatelessWidget {
  const BlogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColor.getMain(),
            title: const Text(AppConstants.appTitle),
            content:  Text(AppTranslationConstants.wantToCloseApp.tr),
            actions: <Widget>[
              TextButton(
                child: Text(AppTranslationConstants.no.tr,
                  style: const TextStyle(color: AppColor.white),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(AppTranslationConstants.yes.tr,
                  style: const TextStyle(color: AppColor.white),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              )
            ],
          ),
        )) ?? false;
      },
      child: GetBuilder<BlogController>(
        id: AppPageIdConstants.blog,
        init: BlogController(),
        builder: (_) => Scaffold(
          appBar: _.profile.id == _.blogOwnerId ? null : AppBarChild(title: "Blog de ${_.mate.name.capitalize}"),
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: _.isLoading ? const Center(child: CircularProgressIndicator(),)
                : DefaultTabController(
                initialIndex: _.tabIndex,
                length: AppConstants.blogTabs.length,
                child: SingleChildScrollView(
                  child: _.profile.id == _.blogOwnerId ?
                  Column(
                    children: <Widget>[
                      TabBar(
                        tabs: [
                          Obx(()=>Tab(text: "${AppConstants.blogTabs.elementAt(0).tr} (${_.blogEntries.length})"),),
                          Obx(()=>Tab(text: "${AppConstants.blogTabs.elementAt(1).tr} (${_.draftEntries.length})"),)
                        ],
                        indicatorColor: Colors.white,
                        labelStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                        unselectedLabelStyle: const TextStyle(fontSize: 13.5),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                      ),
                      SizedBox.fromSize(
                        size: Size.fromHeight(
                            AppTheme.fullHeight(context)),
                        child: TabBarView(
                            children: <Widget>[
                              _.blogEntries.isEmpty ? Center(child: Text(AppTranslationConstants.noEntriesWereFound.tr))
                                  : Obx(()=> buildBlogEntryList(_.blogEntries.values),),
                              _.draftEntries.isEmpty ? Center(child: Text(AppTranslationConstants.noDraftsWereFound.tr))
                                  : Obx(()=> buildBlogEntryList(_.draftEntries.values)),
                            ]
                        ),
                      ),
                    ]) :  SizedBox.fromSize(
                    size: Size.fromHeight(
                        AppTheme.fullHeight(context)),
                        child: Obx(()=> buildBlogEntryList(_.blogEntries.values)),
                  )
                ),
            ),
          ),
          floatingActionButton: _.isLoading ? Container()
              : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  child: AnimatedTextKit(
                    repeatForever: true,
                    animatedTexts: [
                      FlickerAnimatedText(
                          _.draftEntries.isEmpty
                              ? "${AppTranslationConstants.writeYourFeelingOrThinking.tr}  "
                              : ""
                      ),
                    ],
                    onTap: () => {
                      _.gotoNewBlogEntry()
                    },
                  ),
                ),
              ),
              FloatingActionButton(
                heroTag: AppPageIdConstants.itemlist,
                elevation: AppTheme.elevationFAB,
                tooltip: AppTranslationConstants.createBlogEntry.tr,
                child: const Icon(Icons.playlist_add),
                onPressed: () => {
                  _.gotoNewBlogEntry()
                }),
              ])
        )
      )
    );
  }
}
