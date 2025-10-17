import 'package:get/get.dart';

import 'package:neom_core/utils/constants/app_route_constants.dart';

import 'ui/media_upload_page.dart';

class MediaUploadRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRouteConstants.mediaUpload,
      page: () => const MediaUploadPage(),
      transition: Transition.zoom,
    ),
  ];

}
