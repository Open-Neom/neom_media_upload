
abstract class BlogEditorService {

  Future<void> saveBlogEntryDraft();
  Future<void> handleLikePost();
  void setCommentToBlogEntry(String commentId);

}
