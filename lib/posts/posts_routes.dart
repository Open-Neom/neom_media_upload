import 'package:get/get.dart';

import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'ui/add/create_post_text/text_post_page.dart';
import 'ui/add/post_upload_description_page.dart';
import 'ui/add/post_upload_page.dart';
import 'ui/likes_list_page.dart';
import 'ui/post_comments/post_comments_page.dart';
import 'ui/post_details_page.dart';

class PostsRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRouteConstants.postComments,
      page: () => const PostCommentsPage(),
      transition: Transition.fade,
    ),
    GetPage(
        name: AppRouteConstants.postDetails,
        page: () => const PostDetailsPage(),
        transition: Transition.zoom
    ),
    GetPage(
      name: AppRouteConstants.likedProfiles,
      page: () => const LikesListPage(),
    ),
    GetPage(
      name: AppRouteConstants.postUpload,
      page: () => const PostUploadPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.createPostText,
      page: () => const TextPostPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.postUploadDescription,
      page: () => const PostUploadDescriptionPage(),
      transition: Transition.zoom,
    ),
  ];

}
