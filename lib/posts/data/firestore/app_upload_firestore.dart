import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';
import '../../domain/repository/upload_repository.dart';

class AppUploadFirestore implements UploadRepository {

  var logger = Logger();
  final postsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.posts);
  final Reference storageRef = FirebaseStorage.instance.ref();

  @override
  Future<String> uploadImage(String mediaId, File file, UploadImageType uploadImageType) async {
    String imgUrl = "";
    try {
      UploadTask uploadTask = storageRef
          .child("${uploadImageType.name.toLowerCase()}"
          "_$mediaId.jpg").putFile(file);

      TaskSnapshot storageSnap = await uploadTask;
      imgUrl = await storageSnap.ref.getDownloadURL();
    } catch (e) {
      logger.e(e.toString());
    }

    return imgUrl;
  }

  @override
  Future<String> uploadVideo(String mediaId, File file) async {
    UploadTask uploadTask= storageRef.child('video_$mediaId.mp4').putFile(file); //, StorageMetadata(contentType: 'video/mp4')
    TaskSnapshot storageSnap = await uploadTask;
    return await storageSnap.ref.getDownloadURL();
  }

}
