import 'package:neom_core/ui/deferred_loader.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import 'ui/media_upload_page.dart' deferred as mediaUpload;

class MediaUploadRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
      name: AppRouteConstants.mediaUpload,
      page: () => DeferredLoader(mediaUpload.loadLibrary, () => mediaUpload.MediaUploadPage()),
      transition: Transition.zoom,
    ),
  ];

}
