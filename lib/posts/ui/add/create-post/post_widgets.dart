import 'package:flutter/material.dart';

import 'package:neom_commons/core/utils/app_theme.dart';
import '../post_upload_controller.dart';

Widget buildLocationSuggestions(BuildContext context, PostUploadController _) {
  return SizedBox(
    height: 22,
    child: ListView.separated(
        separatorBuilder:  (context, index) => const Divider(),
        itemCount: _.locationSuggestions.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          String locationSuggestion = _.locationSuggestions.elementAt(index);
          return GestureDetector(
            onTap: () {
              _.setUserLocation(locationSuggestion);
            },
            child: Padding(
              padding: const EdgeInsets.only(left:2, right: 2),
              child: Container(
              decoration: index == 0 ? AppTheme.selectedBoxDecoration : AppTheme.boxDecoration,
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: Text(
                locationSuggestion,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),),
          );
        }
        ),
  );
}
