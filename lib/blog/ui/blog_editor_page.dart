
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'blog_editor_controller.dart';

class BlogEditorPage extends StatelessWidget {

  const BlogEditorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    isDarkMode = false;

    return GetBuilder<BlogEditorController>(
        id: AppPageIdConstants.blogEditor,
        init: BlogEditorController(),
        builder: (_) => Obx(()=> Scaffold(
          backgroundColor: const Color.fromRGBO(241, 234, 217, 1),
          body: SafeArea(
            child: _.isLoading.value ? const Center(child: CircularProgressIndicator(),)
            : Container(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTheme.heightSpace20,
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.white.withOpacity(0.5),
                      ),
                      child: TextField(
                          controller: _.entryTitleController,
                          textCapitalization: TextCapitalization.sentences,
                          maxLength: 60,
                          cursorColor: isDarkMode ? Colors.blue.shade100 : AppColor.blogEditor,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey.shade300
                                : Colors.grey.shade800,
                          ),
                          maxLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Título (Opcional)',
                            hintStyle: TextStyle(
                              letterSpacing: 1,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            _.saveDraft(value, isTitle: true);
                          }
                      ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.white.withOpacity(0.5),
                      ),
                      child: TextField(
                        controller: _.entryTextController,
                        textCapitalization: TextCapitalization.sentences,
                        cursorColor:
                            isDarkMode ? Colors.blue.shade100 : AppColor.blogEditor,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                          fontSize: 16,
                          color: isDarkMode
                              ? Colors.grey.shade300
                              : Colors.grey.shade800,
                        ),
                        maxLines: 30,
                        decoration: InputDecoration(
                          hintText: 'Deja que fluya la inspiración...',
                          hintStyle: TextStyle(
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey.shade600 : Colors.grey,
                            height: 1.5,
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          _.saveDraft(value);
                        }
                      ),
                    ),
                  ),
                  AppTheme.heightSpace10,
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(children: [
                        _.profile.value.id == _.blogEntry.value.ownerId ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                child: Text(AppTranslationConstants.goBack.tr,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade700,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: _.entryTextController.text.isNotEmpty,
                              child: Text(
                                'Palabras: ${_.wordQty}',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade700,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                if (!_.isButtonDisabled.value && _.entryTextController.text.isNotEmpty
                                    && _.wordQty >= AppConstants.blogMinWords) {
                                  await _.publishBlogEntry();
                                } else {
                                  Get.snackbar("¡Que siga esa inspiración!",
                                      "Intenta agregar al menos ${AppConstants.blogMinWords - _.wordQty.value} palabras más ;)",
                                      snackPosition: SnackPosition.bottom
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColor.bondiBlue75,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(_.blogEntry.value.isDraft ?
                                AppTranslationConstants.post.tr : AppTranslationConstants.update.tr,
                                  style: TextStyle(
                                    letterSpacing: 1,
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ) : Container(),
                      ],)
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
