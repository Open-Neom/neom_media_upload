import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neom_core/core/app_config.dart';
import 'package:neom_core/core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_core/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_core/core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_core/core/data/firestore/post_firestore.dart';
import 'package:neom_core/core/data/firestore/profile_firestore.dart';
import 'package:neom_core/core/domain/model/activity_feed.dart';
import 'package:neom_core/core/domain/model/post_comment.dart';
import 'package:neom_core/core/utils/enums/activity_feed_type.dart';

import '../../domain/repository/comment_repository.dart';

class CommentFirestore implements CommentRepository {

  final commentReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.comments);

  @override
  Future<List<PostComment>> retrieveComments({required String postId}) async {
    AppConfig.logger.d("RetrievingComments for PostId $postId");
    List<PostComment> comments = [];

    try {

      QuerySnapshot querySnapshot = await commentReference.where(
          AppFirestoreConstants.postId, isEqualTo: postId).get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("Snapshot is not empty");
        for (var commentSnapshot in querySnapshot.docs) {
          PostComment comment = PostComment.fromJSON(commentSnapshot.data());
          comment.id = commentSnapshot.id;
          AppConfig.logger.d(comment.toString());
          comments.add(comment);
        }
        AppConfig.logger.d("${comments .length} comments found");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return comments;
  }


  @override
  Future<String> insert(PostComment comment) async {

    String commentId = "";

    try {
      DocumentReference documentReference = await commentReference
          .add(comment.toJSON());
      commentId = documentReference.id;

      if(await PostFirestore().addComment(comment.postId, commentId)) {
        AppConfig.logger.d("CommentId added to Post");

        await ProfileFirestore().addComment(comment.ownerId, commentId);
        AppConfig.logger.d("CommentId added to Profile");

        if (comment.ownerId != comment.postOwnerId && commentId.isNotEmpty) {
          ActivityFeed activityFeed = ActivityFeed.fromComment(comment: comment, type: ActivityFeedType.comment);
          await ActivityFeedFirestore().insert(activityFeed);
          AppConfig.logger.d("ActivityFeed created for comment");


        } else {
          AppConfig.logger.d("Self Comment");
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return commentId;

  }

  @override
  Future<bool> handleLikeComment(String profileId, String commentId, bool isLiked) async {
    AppConfig.logger.t("handleLikeComment");
    try {
        await commentReference.get()
            .then((querySnapshot) async {
          for (var document in querySnapshot.docs) {
            if(document.id == commentId) {
              isLiked ? await document.reference
                  .update({AppFirestoreConstants.likedProfiles: FieldValue.arrayRemove([profileId])})
              : await document.reference
                  .update({AppFirestoreConstants.likedProfiles: FieldValue.arrayUnion([profileId])});
            }
          }
        });

      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> remove(PostComment comment) async {
    AppConfig.logger.d("Removing comment ${comment.id}");

    try {
      if(await PostFirestore().removeComment(comment.postId, comment.id)) {
        await commentReference.doc(comment.id).delete();
        AppConfig.logger.d("Comment ${comment.id} removed");
      }

      await ProfileFirestore().removeComment(comment.ownerId, comment.id);
      return true;

    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }
  }


}
