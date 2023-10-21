
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'blog_editor_controller.dart';
import 'widgets/blog_widgets.dart';

class BlogEntryPage extends StatelessWidget {

  const BlogEntryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    isDarkMode = false;

    return GetBuilder<BlogEditorController>(
      id: AppPageIdConstants.blogEntry,
      init: BlogEditorController(),
      builder: (_) => Obx(()=> Scaffold(
        backgroundColor: const Color.fromRGBO(241, 234, 217, 1), 
        body: SafeArea(
          child: _.isLoading.value ? const Center(child: CircularProgressIndicator(),)
        : Container(
          padding: const EdgeInsets.all(10),
          width: AppTheme.fullWidth(context),
          height: AppTheme.fullHeight(context),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTheme.heightSpace20,
              Text(_.entryTitleController.text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 18,
                  color: isDarkMode
                      ? Colors.grey.shade300
                      : Colors.grey.shade800,
                ),
                maxLines: 1,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_.entryTextController.text,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                      fontSize: 15,
                      color: isDarkMode
                          ? Colors.grey.shade300
                          : Colors.grey.shade800,
                    ),
                  ),
                ),

              ),
              AppTheme.heightSpace10,
              blogLikeCommentShare(_),
            ])
          ),
        ),
      ),),
    );
  }

}
