//TODO
// Widget commentReply(BuildContext context, Comment comment) {
//   return Container(
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: <Widget>[
//         Expanded(
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.all(Radius.circular(8)),
//               border: Border.all(
//                 style: BorderStyle.solid,
//                   color: Colors.grey, width: 0.5
//               ),
//             ),
//             child: Container(
//               child: Padding(
//                 padding: EdgeInsets.all(10.0),
//                 child: Column(
//                   children: <Widget>[
//                     Comment.mediaUrl.isEmpty ? Container() :
//                     cachedNetworkImage(Comment.mediaUrl),
//                     Comment.text.isEmpty ? Container() :
//                     Text(Comment.text,
//                         softWrap: true,
//                         maxLines: 3,
//                         style: TextStyle(fontSize: 14)),
//                     AppTheme.heightSpace10,
//                     Divider(thickness: 1),
//                     menuCommentReply(Comment),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//         AppTheme.widthSpace20,
//         CircleAvatar(
//             backgroundColor: Colors.grey,
//             child: ClipOval(
//                 child: Image.network(comment.ownerImgUrl)
//             ),
//             radius: 20),
//       ],
//     ),
//   );
// }

// Widget menuCommentReply(Comment Comment) {
//   return Row(
//     mainAxisAlignment: MainAxisAlignment.spaceAround,
//     crossAxisAlignment: CrossAxisAlignment.center,
//     children: <Widget>[
//       GestureDetector(
//           onTap: () => debugPrint('${Comment.likedProfiles} tapped'),
//           child: Row(
//             children: <Widget>[
//               Icon(
//                 FontAwesomeIcons.heart,
//                 size: 16,
//                 color: Colors.white,
//               ),
//               AppTheme.widthSpace5,
//               Text(timeago.format(DateTime.fromMillisecondsSinceEpoch(Comment.createdTime), locale: 'en_short'),
//                   style: TextStyle(fontSize: 14, color: Colors.grey[700])),
//               Divider(thickness: 1),
//               Text(
//                 '${Comment.likedProfiles}',
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold),
//               )
//             ],
//           )
//       ),
//     ],
//   );
// }

// TODO VERIFY
// Widget othersCommentWithImageSlider(BuildContext context, Comment Comment) {
//   return Container(
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: <Widget>[
//         CircleAvatar(
//             backgroundColor: Colors.grey,
//             child: ClipOval(
//                 child: Image.network(comment.ownerImgUrl)
//             ),
//             radius: 20),
//         AppTheme.widthSpace20,
//         Expanded(
//             child: Container(
//           decoration: BoxDecoration(
//               borderRadius: BorderRadius.all(Radius.circular(8)),
//               border: Border.all(
//                   style: BorderStyle.solid, color: Colors.grey, width: 0.5)),
//           child: Card(
//             elevation: 0,
//             child: Padding(
//               padding: EdgeInsets.all(10.0),
//               child: Column(
//                 children: <Widget>[
//                   usernameSectionWithoutAvatar(context, Comment),
//                   AppTheme.heightSpace10,
//                   Text(Comment.text,
//                       softWrap: true,
//                       maxLines: 3,
//                       style: TextStyle(fontSize: 14)),
//                   AppTheme.heightSpace10,
//                   imageCarouselSlider(context, [Constants.noImageUrl]),
//                   Divider(thickness: 1),
//                   AppTheme.heightSpace10,
//                   //menuReply(Comment),
//                   AppTheme.heightSpace10,
//                 ],
//               ),
//             ),
//           ),
//         )
//             //commentReply(context, FeedBloc().feedList[2]),
//             )
//       ],
//     ),
//   );
// }

//TODO VERIFY
// Widget imageCarouselSlider(BuildContext buildContext, List<String> imgUrls) {
//   return CarouselSlider(
//     options: CarouselOptions(
//       height: AppTheme.fullHeight(buildContext) * 0.35,
//         aspectRatio: 16/9,
//         onPageChanged: (int pageIndex, CarouselPageChangedReason carouselPageChangedReason) {
//           if(carouselPageChangedReason == CarouselPageChangedReason.manual){
//
//           }
//         },
//         enlargeCenterPage: true,
//       enableInfiniteScroll: true,
//       autoPlay: true,
//       scrollDirection: Axis.horizontal,
//       autoPlayAnimationDuration: Duration(milliseconds: 800),
//       autoPlayCurve: Curves.fastOutSlowIn
//     ),
//     items: imgUrls.map((imgUrl) {
//       return Builder(
//         builder: (BuildContext context) {
//           return Container(
//             width: AppTheme.fullWidth(context),
//             child: CachedNetworkImage(imageUrl: imgUrl.isNotEmpty ? imgUrl : Constants.noImageUrl, fit: BoxFit.fill)
//           );
//         },
//       );
//     }).toList(),
//   );
// }

// TODO VERIFY
// Widget menuReply(Comment Comment) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: <Widget>[
//       Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: <Widget>[
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               GestureDetector(
//                 onTap: () => debugPrint('${Comment.likedProfiles.length} tapped'),
//                 child: Text('${Comment.likedProfiles.length} ${TranslationConstants.likes.tr}',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold),
//                 ),
//               ),
//               AppTheme.widthSpace10,
//               GestureDetector(
//                 onTap: () => print(""),
//                 child: Text('${Comment.Replies.length} ${TranslationConstants.replies.tr}',
//                 style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
//               ),
//             ],
//           ),
//           Text(TranslationConstants.toReply.tr,
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 12,
//               fontWeight: FontWeight.bold)
//           ),
//         ],
//       ),
//     ],
//   );
// }
