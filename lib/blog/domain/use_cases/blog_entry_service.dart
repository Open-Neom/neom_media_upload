import 'package:neom_commons/core/domain/model/post.dart';

abstract class BlogEntryService {

  Future<void> updateBlogEntry(String blogEntryId, Post blogEntry);
  Future<void> gotoNewBlogEntry();
  Future<void> getBlogEntries();

}
