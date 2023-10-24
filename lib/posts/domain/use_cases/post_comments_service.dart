import 'package:flutter/cupertino.dart';
import 'package:neom_commons/core/domain/model/post_comment.dart';
import 'package:neom_commons/core/utils/enums/app_file_from.dart';

abstract class PostCommentsService {

  Future<void> addComment();
  Future<void> handleImage(AppFileFrom fileFrom);
  void clearComment();
  void clearImage();
  bool isLikedComment(PostComment comment);
  Future<void> handleLikeComment(PostComment comment);
  Future<void> hideComment(PostComment comment);
  Future<void> removeComment(PostComment comment);
  void addCommentToList(PostComment newComment);
  Future<void> showHideCommentAlert(BuildContext context, PostComment comment);
  Future<void> showRemoveCommentAlert(BuildContext context, PostComment comment);
  Future<void> showBlockProfileAlert(BuildContext context, String commentOwnerId);
}
