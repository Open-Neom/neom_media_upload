
import 'package:neom_core/core/domain/model/post.dart';

abstract class PostDetailsService {

  Future<void> retrievePost();
  void showPostInfo(bool show);
  bool isLikedPost(Post post);
  Future<void> handleLikePost(Post post);
  bool verifyIfCommented(List<String> postCommentIds, List<String> profileCommentIds);
  void setCommentToPost(String commentId);

}
