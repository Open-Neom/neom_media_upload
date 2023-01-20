import 'package:neom_commons/core/domain/model/post_comment.dart';

abstract class CommentRepository {

  Future<String> insert(PostComment comment);
  Future<bool> remove(PostComment comment);
  Future<List<PostComment>> retrieveComments({required String postId});
  Future<bool> handleLikeComment(String profileId, String commentId, bool isLiked);

}
