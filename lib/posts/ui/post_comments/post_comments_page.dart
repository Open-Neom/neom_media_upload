import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';

import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import '../widgets/posts_widgets.dart';
import 'post_comments_controller.dart';
import 'post_comments_widgets.dart';


class PostCommentsPage extends StatelessWidget {

  const PostCommentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostCommentsController>(
      id: AppPageIdConstants.postComments,
      init: PostCommentsController(),
      builder: (_) => SafeArea(
        child: Scaffold(
          backgroundColor: AppColor.main50,
          ///DEPRECATED
          /// appBar: AppBarChild(title: AppTranslationConstants.comments.tr),
          body: _.isLoading ? const AppCircularProgressIndicator() : Container(
            decoration: AppTheme.appBoxDecoration,
            height: AppTheme.fullHeight(context),
            padding: const EdgeInsets.all(AppTheme.padding10),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    reverse: true,
                    child: Column(
                      children: <Widget>[
                         shortFeedNewsCardItem(context, _),
                        AppTheme.heightSpace10,
                        Obx(()=>buildCommentList(context, _)),
                        AppTheme.heightSpace50,
                        AppTheme.heightSpace30,
                      ],
                    ),
                  ),
                  Positioned(bottom: 0.0, left: 0.0, right: 0.0,
                    child: buildCommentComposer(context, _),
                  ),
                ]
              )
          ),
        ),
      ),
    );
  }

}
