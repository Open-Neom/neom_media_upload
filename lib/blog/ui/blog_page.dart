import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/core/utils/constants/core_constants.dart';
import 'blog_controller.dart';
import 'widgets/blog_widgets.dart';

class BlogPage extends StatelessWidget {
  const BlogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: GetBuilder<BlogController>(
        id: AppPageIdConstants.blog,
        init: BlogController(),
        builder: (_) => Obx(()=> Scaffold(
          appBar: _.isLoading.value ? null : AppBarChild(title: _.profile.id == _.blogOwnerId ? "Blog Inspiracional":"Blog de ${_.mate.name.capitalize}"),
            backgroundColor: AppColor.main50,
            body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: _.isLoading.value ? const AppCircularProgressIndicator()
                : DefaultTabController(
                initialIndex: _.tabIndex,
                length: CoreConstants.blogTabs.length,
                child: SingleChildScrollView(
                  child: _.profile.id == _.blogOwnerId ?
                  Column(
                    children: <Widget>[
                      TabBar(
                        tabs: [
                          Tab(text: "${CoreConstants.blogTabs.elementAt(0).tr} (${_.blogEntries.length})"),
                          Tab(text: "${CoreConstants.blogTabs.elementAt(1).tr} (${_.draftEntries.length})")
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
                                  : buildBlogEntryList(_.blogEntries.values),
                              _.draftEntries.isEmpty ? Center(child: Text(AppTranslationConstants.noDraftsWereFound.tr))
                                  : buildBlogEntryList(_.draftEntries.values)
                            ]
                        ),
                      ),
                    ]) :  SizedBox.fromSize(
                    size: Size.fromHeight(
                        AppTheme.fullHeight(context)),
                        child: buildBlogEntryList(_.blogEntries.values),
                  )
                ),
            ),
          ),
          floatingActionButton: _.isLoading.value ? const SizedBox.shrink()
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
                    onTap: () => _.gotoNewBlogEntry()
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
              ],
          )
        ),),
      )
    );
  }
}
