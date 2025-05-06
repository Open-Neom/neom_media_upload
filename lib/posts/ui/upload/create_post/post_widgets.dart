import 'package:flutter/material.dart';

import 'package:neom_commons/core/utils/app_theme.dart';
import '../post_upload_controller.dart';

Widget buildLocationSuggestions(BuildContext context, PostUploadController _) {
  List<String> suggestions = _.locationSuggestions.value;

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 5, // Mayor valor para reducir altura
    ),
    itemCount: suggestions.length,
    itemBuilder: (context, index) {
      String locationSuggestion = suggestions[index];
      return GestureDetector(
        onTap: () => _.setUserLocation(locationSuggestion),
        child: Container(
          decoration: index == 0
              ? AppTheme.selectedBoxDecoration
              : AppTheme.boxDecoration,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // padding reducido
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              locationSuggestion,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      );
    },
  );
}
