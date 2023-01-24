import 'package:get/get.dart';

import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'ui/blog_editor_page.dart';
import 'ui/blog_entry_page.dart';
import 'ui/blog_mate_page.dart';
import 'ui/blog_page.dart';

class BlogRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRouteConstants.blog,
      page: () => const BlogPage(),
    ),
    GetPage(
      name: AppRouteConstants.blogEditor,
      page: () => const BlogEditorPage(),
    ),
    GetPage(
      name: AppRouteConstants.mateBlog,
      page: () => const BlogMatePage(),
    ),
    GetPage(
      name: AppRouteConstants.blogEntry,
      page: () => const BlogEntryPage(),
    ),
  ];

}
