import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'blog_controller.dart';
import 'widgets/blog_widgets.dart';

class BlogMatePage extends StatelessWidget {
  const BlogMatePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BlogController>(
        id: AppPageIdConstants.blog,
        init: BlogController(),
        builder: (_) => Scaffold(
          appBar: AppBarChild(title: "Blog de ${_.mate.name.capitalize}"),
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: DefaultTabController(
                initialIndex: _.tabIndex,
                length: AppConstants.blogTabs.length,
                child: SingleChildScrollView(
                  child: SizedBox.fromSize(
                    size: Size.fromHeight(
                        AppTheme.fullHeight(context)),
                        child: Obx(()=> buildBlogEntryList(_.blogEntries.values)),
                  )
                ),
            ),
          ),
        )
    );
  }
}
