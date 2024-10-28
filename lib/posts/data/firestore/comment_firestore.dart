import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neom_commons/core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_commons/core/data/firestore/post_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/domain/model/activity_feed.dart';
import 'package:neom_commons/core/domain/model/post_comment.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/enums/activity_feed_type.dart';

import '../../domain/repository/comment_repository.dart';

class CommentFirestore implements CommentRepository {

  final commentReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.comments);

  @override
  Future<List<PostComment>> retrieveComments({required String postId}) async {
    AppUtilities.logger.d("RetrievingComments for PostId $postId");
    List<PostComment> comments = [];

    try {

      QuerySnapshot querySnapshot = await commentReference.where(
          AppFirestoreConstants.postId, isEqualTo: postId).get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.d("Snapshot is not empty");
        for (var commentSnapshot in querySnapshot.docs) {
          PostComment comment = PostComment.fromJSON(commentSnapshot.data());
          comment.id = commentSnapshot.id;
          AppUtilities.logger.d(comment.toString());
          comments.add(comment);
        }
        AppUtilities.logger.d("${comments .length} comments found");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
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
        AppUtilities.logger.d("CommentId added to Post");

        await ProfileFirestore().addComment(comment.ownerId, commentId);
        AppUtilities.logger.d("CommentId added to Profile");

        if (comment.ownerId != comment.postOwnerId && commentId.isNotEmpty) {
          ActivityFeed activityFeed = ActivityFeed.fromComment(comment: comment, type: ActivityFeedType.comment);
          await ActivityFeedFirestore().insert(activityFeed);
          AppUtilities.logger.d("ActivityFeed created for comment");


        } else {
          AppUtilities.logger.d("Self Comment");
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return commentId;

  }

  @override
  Future<bool> handleLikeComment(String profileId, String commentId, bool isLiked) async {
    AppUtilities.logger.t("handleLikeComment");
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
      AppUtilities.logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> remove(PostComment comment) async {
    AppUtilities.logger.d("Removing comment ${comment.id}");

    try {
      if(await PostFirestore().removeComment(comment.postId, comment.id)) {
        await commentReference.doc(comment.id).delete();
        AppUtilities.logger.d("Comment ${comment.id} removed");
      }

      await ProfileFirestore().removeComment(comment.ownerId, comment.id);
      return true;

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }
  }


}
