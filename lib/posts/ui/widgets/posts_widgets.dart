import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/core/domain/model/post_comment.dart';
import 'package:neom_core/core/utils/enums/app_file_from.dart';
import 'package:neom_core/core/utils/enums/app_media_type.dart';

import '../post_comments/post_comments_controller.dart';
import '../post_comments/post_comments_widgets.dart';

Widget buildCommentList(BuildContext context, PostCommentsController _) {
  return ListView.separated(
      shrinkWrap: true,
      controller: _.scrollController,
      itemCount: _.comments.length,
      separatorBuilder: (context, index) => AppTheme.heightSpace5,
      itemBuilder: (context, index) {
        PostComment comment = _.comments.elementAt(index);
        Widget widget = const SizedBox.shrink();
        if(comment.postOwnerId == comment.ownerId) {
          //TODO Comment Reply when self
          //widget = commentReply(context, comment);
          widget = othersComment(context, _,  comment);
        } else {
          switch (comment.type) {
            case AppMediaType.text:
              widget = othersComment(context, _, comment);
              break;
            case AppMediaType.image:
              widget = othersComment(context, _, comment);
              break;
            case AppMediaType.imageSlider:
            // TODO
            //widget = othersCommentWithImageSlider(context, comment);
              break;
            case AppMediaType.video:
            //TODO
              break;
            case AppMediaType.gif:
            //TODO
              break;
            case AppMediaType.youtube:
            //TODO
              break;
            case AppMediaType.eventImage:
            //TODO
              break;
            default:
              break;
          }
        }

        return widget;
      }
  );

}

Widget buildCommentComposer(BuildContext context, PostCommentsController _,) {
  return Row(
    children: [
      SizedBox(
        child: (_.postUploadController.mediaFile.value.path.isEmpty || _.sendingMessage.value) ?
        IconButton(
            icon: const Icon(Icons.photo),
            iconSize: 25.0,
            color: Theme.of(context).primaryColorLight,
            onPressed: () async => await _.handleImage(AppFileFrom.gallery)
        ) :
        Stack(
            children: [
              Container(
                  width: 40.0, height: 40.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(52), // Add rounded corners here
                  ),
                  child: fileImage(_.postUploadController.mediaFile.value.path)
              ),
              Positioned(
                width: 20, height: 20,
                top: 30, left: 30,
                child: FloatingActionButton(
                    backgroundColor: Theme.of(context).primaryColorLight,
                    child: const Icon(Icons.close, color: Colors.white70, size: 15),
                    onPressed: () => _.clearImage()
                ),
              ),
            ]
        ),
      ),
      if(_.postUploadController.mediaFile.value.path.isNotEmpty) AppTheme.widthSpace10,
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            color: AppColor.main50,
            borderRadius: BorderRadius.circular(12), // Add rounded corners here
          ),
          child: TextField(
            controller: !_.sendingMessage.value ? _.commentController : TextEditingController(),
            minLines: 1,
            maxLines: 20,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: '${AppTranslationConstants.toComment.tr}...',
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      if(_.sendingMessage.value) AppTheme.widthSpace5,
      Container(
        child: _.sendingMessage.value ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator())
            : IconButton(
          icon: const Icon(Icons.send),
          iconSize: 25.0,
          color: Theme.of(context).primaryColorLight,

          onPressed: () => _.sendingMessage.value || _.commentController.text.isEmpty ? {} : _.addComment(),
        ),
      )
    ],
  );
}
