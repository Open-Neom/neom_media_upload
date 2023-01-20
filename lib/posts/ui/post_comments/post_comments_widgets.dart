// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:hashtagable/hashtagable.dart';
import 'package:neom_commons/core/data/implementations/mate_controller.dart';
import 'package:neom_commons/core/domain/model/menu_three_dots.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:neom_commons/core/domain/model/post_comment.dart';
import 'package:neom_commons/core/ui/reports/report_controller.dart';
import 'package:neom_commons/core/ui/widgets/custom_image.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/emxi_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/reference_type.dart';
import 'package:neom_commons/core/utils/enums/report_type.dart';
import 'package:neom_commons/core/utils/enums/user_role.dart';
import 'post_comments_controller.dart';

Widget othersComment(BuildContext context, PostCommentsController _, PostComment comment) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      GestureDetector(
        onTap: () => _.profile.id == comment.profileId ? Get.toNamed(AppRouteConstants.profile)
            : Get.toNamed(AppRouteConstants.mateDetails, arguments: comment.profileId),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          backgroundImage: CachedNetworkImageProvider(comment.profileImgUrl),
          radius: 15
        ),
      ),
      AppTheme.widthSpace10,
      Expanded(
        child: Container(
          decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(
            style: BorderStyle.solid, color: Colors.grey, width: 0.5)),
          child: Card(
            color: AppColor.getContextCardColor(context),
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: <Widget>[
                usernameSectionWithoutAvatar(context, _.profile.id, comment,
                    role: _.userController.user?.userRole ?? UserRole.subscriber),
                AppTheme.heightSpace5,
                (comment.mediaUrl.isEmpty ||  comment.mediaUrl == _.post.mediaUrl) ? Container() :
                Column(
                  children: [
                    SizedBox(
                        height: 250,
                        width: 250,
                        child: customCachedNetworkHeroImage(comment.mediaUrl)),
                  AppTheme.heightSpace5,
                ],),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    comment.text.isEmpty ? Container() :
                    Expanded(
                      child: Text(
                        comment.text,
                        maxLines: 20,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      icon: Icon(_.isLikedComment(comment) ? FontAwesomeIcons.solidHeart
                          :  FontAwesomeIcons.heart, size: AppTheme.postIconSize),
                      onPressed: () => _.handleLikeComment(comment),
                    ),
                  ],
                ),
                AppTheme.heightSpace5,
                //TODO
                //Divider(thickness: 1),
                //menuReply(comment),
              ],
            ),
          ),
        ),
      )
      )
    ],
  );
}


Widget usernameSectionWithoutAvatar(BuildContext context, String profileId, PostComment comment,
    {showDots = true, UserRole role = UserRole.subscriber}
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GestureDetector(
                    onTap: () => profileId == comment.profileId ? Get.toNamed(AppRouteConstants.profile)
                        : Get.toNamed(AppRouteConstants.mateDetails, arguments: comment.profileId),
                    child: Text(comment.profileName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                      ))
                    ,
                  ),
                  const SizedBox(width: 10),
                  Text(timeago.format(
                      DateTime.fromMillisecondsSinceEpoch(comment.createdTime),
                      locale: 'en_short'),
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700]
                      )
                  ),                  
                ],
              ),
            ],
          )
        ],
      ),
      showDots ? IconButton(
          constraints: const BoxConstraints(),
          onPressed: () => showModalBottomSheet(
              backgroundColor: AppTheme.canvasColor75(context),
              context: context,
              builder: (context) {
                return _buildCommentBottomNavMenu(context,
                    profileId == comment.profileId, comment, role);
              }),
          icon: const Icon(FontAwesomeIcons.ellipsisVertical, size: 20)
      ) : Container(),            //moreOptions3Dots(context),
    ],
  );
}


Widget _buildCommentBottomNavMenu(BuildContext context, bool isSelf, PostComment comment, UserRole userRole) {
  List<Menu3DotsModel> listMore = [];

  if(isSelf) {
    //TODO Edit Comment
    listMore.add(Menu3DotsModel(AppTranslationConstants.removeComment, AppTranslationConstants.removeCommentMsg,
        Icons.delete, AppTranslationConstants.removeComment));
  } else {
    listMore.add(Menu3DotsModel(AppTranslationConstants.hideComment, AppTranslationConstants.hideCommentMsg,
        Icons.hide_source, AppTranslationConstants.hideComment));
    listMore.add(Menu3DotsModel(AppTranslationConstants.reportComment, AppTranslationConstants.reportCommentMsg,
        Icons.info, AppTranslationConstants.reportComment));
    listMore.add(Menu3DotsModel('${AppTranslationConstants.toBlock.tr} ${comment.profileName}',
        AppTranslationConstants.blockProfileMsg, Icons.block, AppTranslationConstants.blockProfile));

    if(userRole != UserRole.subscriber) {
      listMore.add(Menu3DotsModel(AppTranslationConstants.removeComment, AppTranslationConstants.reportCommentMsg,
          Icons.delete, AppTranslationConstants.removeComment));
    }
  }
  return Container(
      height: isSelf ? 100 : 300,
      decoration: BoxDecoration(
        color: AppColor.main50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: ListView.builder(
          itemCount: listMore.length,
          itemBuilder: (BuildContext context, int index){
            return ListTile(
              title: Text(listMore[index].title.tr, style: const TextStyle(fontSize: 18)),
              subtitle: Text(listMore[index].subtitle.tr),
              leading: Icon(listMore[index].icons, size: 20, color: Colors.white),
              onTap: () async {
                switch (listMore[index].action) {
                  case AppTranslationConstants.editPost:
                    Get.snackbar(AppTranslationConstants.underConstruction.tr,
                        AppTranslationConstants.underConstructionMsg.tr,
                        snackPosition: SnackPosition.bottom
                    );
                    break;
                  case AppTranslationConstants.hideComment:
                    Alert(
                        context: context,
                        style: AlertStyle(
                          backgroundColor: AppColor.main50,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        title: AppTranslationConstants.hideComment.tr,
                        content: Column(
                          children: [
                            Text(AppTranslationConstants.hideCommentMsg2.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],),
                        buttons: [
                          DialogButton(
                            color: AppColor.bondiBlue75,
                            onPressed: () async {
                              Get.back();
                            },
                            child: Text(AppTranslationConstants.goBack.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          DialogButton(
                            color: AppColor.bondiBlue75,
                            onPressed: () async {
                              await Get.find<PostCommentsController>().hideComment(comment);
                              AppUtilities.showAlert(context, AppTranslationConstants.hideComment.tr, AppTranslationConstants.hiddenCommentMsg.tr);
                            },
                            child: Text(AppTranslationConstants.toHide.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          )
                        ]
                    ).show();
                    break;
                  case AppTranslationConstants.reportComment:
                    ReportController reportController = Get.put(ReportController());
                    //_.alreadySent ? {} :
                    Alert(
                        context: context,
                        style: AlertStyle(
                          backgroundColor: AppColor.main50,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        title: AppTranslationConstants.sendReport.tr,
                        content: Column(
                          children: <Widget>[
                            Obx(()=>
                                DropdownButton<String>(
                                  items: ReportType.values.map((ReportType reportType) {
                                    return DropdownMenuItem<String>(
                                      value: reportType.name,
                                      child: Text(reportType.name.tr),
                                    );
                                  }).toList(),
                                  onChanged: (String? reportType) {
                                    reportController.setReportType(reportType ?? "");
                                  },
                                  value: reportController.reportType,
                                  alignment: Alignment.center,
                                  icon: const Icon(Icons.arrow_downward),
                                  iconSize: 20,
                                  elevation: 16,
                                  style: const TextStyle(color: Colors.white),
                                  dropdownColor: AppColor.main75,
                                  underline: Container(
                                    height: 1,
                                    color: Colors.grey,
                                  ),
                                ),
                            ),
                            TextField(
                              onChanged: (text) {
                                reportController.setMessage(text);
                              },
                              decoration: InputDecoration(
                                  labelText: AppTranslationConstants.message.tr
                              ),
                            ),
                          ],
                        ),
                        buttons: [
                          DialogButton(
                            color: AppColor.bondiBlue75,
                            onPressed: () async {
                              if(!reportController.isButtonDisabled) {
                                await reportController.sendReport(ReferenceType.comment, comment.id);
                                AppUtilities.showAlert(context, AppTranslationConstants.report.tr, AppTranslationConstants.hasSentReport.tr);
                              }
                            },
                            child: Text(AppTranslationConstants.send.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          )
                        ]
                    ).show();
                    break;
                  case AppTranslationConstants.blockProfile:
                    MateController itemmateController = Get.put(MateController());
                    Alert(
                        context: context,
                        style: AlertStyle(
                          backgroundColor: AppColor.main50,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        title: AppTranslationConstants.blockProfile.tr,
                        content: Column(
                          children: [
                            Text(AppTranslationConstants.blockProfileMsg.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                            AppTheme.heightSpace10,
                            Text(AppTranslationConstants.blockProfileMsg2.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],),
                        buttons: [
                          DialogButton(
                            color: AppColor.bondiBlue75,
                            onPressed: () async {
                              Get.back();
                            },
                            child: Text(AppTranslationConstants.goBack.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          DialogButton(
                            color: AppColor.bondiBlue75,
                            onPressed: () async {
                              if(!itemmateController.isButtonDisabled) {
                                await itemmateController.block(comment.profileId);
                                AppUtilities.showAlert(context, AppTranslationConstants.blockProfile.tr, AppTranslationConstants.blockedProfileMsg.tr);
                              }
                            },
                            child: Text(AppTranslationConstants.toBlock.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          )
                        ]
                    ).show();
                    break;
                  case AppTranslationConstants.removeComment:
                    Alert(
                        context: context,
                        style: AlertStyle(
                          backgroundColor: AppColor.main50,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        title: AppTranslationConstants.removeThisPost.tr,
                        content: Column(
                          children: [
                            Text(AppTranslationConstants.removePostMsg.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],),
                        buttons: [
                          DialogButton(
                            color: AppColor.bondiBlue75,
                            onPressed: () async {
                              Get.back();
                            },
                            child: Text(AppTranslationConstants.goBack.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          DialogButton(
                            color: AppColor.bondiBlue75,
                            onPressed: () async {
                              await Get.find<PostCommentsController>().removeComment(comment);
                              AppUtilities.showAlert(context,
                                  AppTranslationConstants.removeComment.tr,
                                  AppTranslationConstants.removedCommentMsg.tr
                              );
                            },
                            child: Text(AppTranslationConstants.toRemove.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          )
                        ]
                    ).show();
                    break;
                }
                //Get.back();
              },
            );
          })
  );
}

Widget shortFeedNewsCardItem(BuildContext context, PostCommentsController _) {
  String caption = _.post.caption;
  if(caption.contains(EmxiConstants.titleTextDivider)) {
    caption = caption.split(EmxiConstants.titleTextDivider)[1];
  }

  return Container(
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      border: Border.all(style: BorderStyle.solid, color: Colors.grey, width: 0.5),
    ),
    child: Card(
      elevation: 0,
      color: AppColor.getContextCardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: <Widget>[
            userAvatarSection(context, _.profile.id, _.post,
                role: _.userController.user!.userRole),
            AppTheme.heightSpace5,
            Visibility(
                visible: caption.isNotEmpty,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: (caption.contains("http") || caption.contains("https"))
                        ?
                    Linkify(
                      onOpen: (link)  {
                        CoreUtilities.launchURL(link.url);
                      },
                      text: caption,
                      maxLines: 20,
                      style: const TextStyle(fontSize: 16),
                      linkStyle: const TextStyle(fontSize: 16, color: AppColor.dodgetBlue),
                    ) :
                    HashTagText(
                      text: caption,
                      softWrap: true,
                      maxLines: 20,
                      basicStyle: const TextStyle(fontSize: 16),
                      decoratedStyle: const TextStyle(fontSize: 16, color: AppColor.dodgetBlue),
                      onTap: (text) {
                        AppUtilities.logger.e(text);
                      },
                    )
                )
            )
          ],
        ),
      ),
    ),
  );
}
