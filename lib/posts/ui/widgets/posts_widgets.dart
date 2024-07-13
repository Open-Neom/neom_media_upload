import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/neom_commons.dart';

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

Widget buildCommentComposer(BuildContext context, PostCommentsController _) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10.0),
    height: 80.0,
    color: AppColor.getMain(),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        (_.postUploadController.croppedImageFile.value.path.isEmpty) ?
        IconButton(
            icon: const Icon(Icons.photo),
            iconSize: 25.0,
            color: Theme.of(context).primaryColorLight,
            onPressed: () async => await _.handleImage(AppFileFrom.gallery)
        ) :
        Stack(
            children: [
              SizedBox(
                  width: 50.0,
                  height: 50.0,
                  child: fileImage(_.postUploadController.croppedImageFile.value.path)
              ),
              Positioned(
                width: 20,
                height: 20,
                top: 30,
                left: 30,
                child: FloatingActionButton(
                    backgroundColor: Theme.of(context).primaryColorLight,
                    child: const Icon(Icons.close, color: Colors.white70, size: 15),
                    onPressed:  ()=> _.clearImage()
                ),
              ),
            ]
        ),
        AppTheme.widthSpace10,
        Expanded(
          child: TextField(
            controller: _.commentController,
            //TODO Verify how to improve this
            minLines: 1,
            maxLines: 20,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: AppTranslationConstants.writeComment.tr,
              border: InputBorder.none,
            ),
          ),
        ),
        IconButton(
            icon: const Icon(Icons.send),
            iconSize: 25.0,
            color: Theme.of(context).primaryColorLight,
            onPressed: () => {
              if(!_.isButtonDisabled.value) _.addComment()
            }
        ),
      ],
    ),
  );
}
